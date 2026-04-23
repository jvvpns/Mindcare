import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/intelligence_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/kelly_context_service.dart';
import '../../core/services/kelly_emotion_service.dart';
import 'kelly_state_provider.dart';
import 'chat_safety_provider.dart';
import 'chat_session_provider.dart';
import 'usage_provider.dart';
import '../../planner/providers/planner_provider.dart';
import 'dart:async';

/// Provides the singleton Intelligence API gateway.
final intelligenceServiceProvider = Provider<IntelligenceService>((ref) => IntelligenceService.instance);

/// Provides the local Gemini Service to handle function calling natively.
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

/// Indicates whether Kelly is currently loading her context (first session init).
/// Starts as false — only goes true when loading a SAVED past session from Hive.
final chatInitializingProvider = StateProvider<bool>((ref) => false);

/// Indicates whether Kelly is currently typing a reply.
final chatLoadingProvider = StateProvider<bool>((ref) => false);

/// Central provider for managing the entire conversation list.
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
  (ref) => ChatMessagesNotifier(ref),
);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  final _uuid = const Uuid();

  ChatMessagesNotifier(this._ref) : super([]) {
    // Fire immediately for the initial session (null = New Chat).
    _initSession(sessionId: null);

    // Listen only to ACTUAL session ID changes (switching to a saved session).
    _ref.listen<String?>(
      currentSessionIdProvider,
      (previous, next) {
        // Only re-init when the session ID actually changes value
        if (previous != next) {
          _initSession(sessionId: next);
        }
      },
    );
  }

  /// Hybrid context init with efficiency optimizations.
  /// - New Chat (sessionId == null): zero history sent to Gemini, fresh greeting.
  /// - Saved Session: loads last 15 messages (not 30) for faster context replay.
  Future<void> _initSession({String? sessionId}) async {
    _ref.read(chatLoadingProvider.notifier).state = false;

    // Only show spinner when loading a heavy saved session from Hive.
    if (sessionId != null) {
      _ref.read(chatInitializingProvider.notifier).state = true;
    }

    try {
      final localContext = LocalContextService.instance;
      final gemini = _ref.read(geminiServiceProvider);

      // ── Part 1: Initial Greeting ──────────────────────────────────────────
      if (sessionId == null) {
        state = [_buildGreeting()];
        final snapshot = localContext.buildLocalSnapshot();
        gemini.startSessionWithContext(userContextSummary: snapshot.toString());
        return;
      }

      // ── Part 2: Session Rehydration (Hybrid) ──────────────────────────────
      // On launch/session switch, we rehydrate from local first for speed
      final localSnapshot = localContext.buildLocalSnapshot();
      
      // Load UI messages from local Hive
      final allMessages = HiveService.chatBox.values
          .where((m) => m.sessionId == sessionId)
          .toList();
      allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      final recent = allMessages.length > 15 
          ? allMessages.sublist(allMessages.length - 15) 
          : allMessages;

      final uiMessages = recent.map((m) => ChatMessage(
        id: m.id,
        text: m.content,
        isUser: m.role == 'user',
        timestamp: m.sentAt,
      )).toList();

      state = uiMessages.isNotEmpty ? uiMessages : [_buildGreeting()];

      // ── Part 3: Backend Warm-up (Cold Start Handling) ─────────────────────
      gemini.startSessionWithContext(
        userContextSummary: localSnapshot.toString(),
        history: uiMessages.map((m) => Content(
          m.isUser ? 'user' : 'model',
          [TextPart(m.text)],
        )).toList(),
      );

    } catch (e) {
      state = [_buildGreeting()];
    } finally {
      _ref.read(chatInitializingProvider.notifier).state = false;
    }
  }

  /// Builds a grounded, local-aware greeting for Kelly.
  ChatMessage _buildGreeting() {
    String greetingText;
    try {
      final now = DateTime.now();
      final todayMood = LocalContextService.instance.getTodayMood(now);
      if (todayMood != null) {
        greetingText = "Hey! I see you're feeling ${todayMood.toLowerCase()} today 😊 I'm right here if you want to talk about it.";
      } else {
        greetingText = "Hi there! I'm Kelly. I'm here if you need to vent about clinicals or just talk. How are you feeling right now?";
      }
    } catch (_) {
      greetingText = "Hi! I'm Kelly. How can I help you today?";
    }
    return ChatMessage(
      id: 'init_${DateTime.now().millisecondsSinceEpoch}',
      text: greetingText,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }


  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    // ── Safety Guard: Prevent multiple messages while processing ──────────
    if (_ref.read(chatLoadingProvider)) return;

    // ── Energy Guard: Kelly needs stamina to reply ────────────────────────
    final canSend = _ref.read(usageProvider.notifier).incrementUsage();
    if (!canSend) {
      debugPrint("ChatFlow: Kelly out of energy.");
      return;
    }

    final emotion = KellyEmotionService.detectEmotion(text);
    _ref.read(kellyEmotionProvider.notifier).state = emotion;

    if (KellyEmotionService.isCrisis(text)) {
      _ref.read(isCrisisActiveProvider.notifier).state = true;
    }

    String? currentSessionId = _ref.read(currentSessionIdProvider);
    if (currentSessionId == null) {
      final sessionNotifier = _ref.read(chatSessionsProvider.notifier);
      final newSession = await sessionNotifier.createSession(text);
      currentSessionId = newSession.id;
    }

    // 1. Optimistic UI
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      detectedEmotion: emotion,
    );
    state = [...state, userMsg];

    // 2. Persist Locally
    await LocalContextService.instance.persistMessage(
      content: text,
      role: 'user',
      sessionId: currentSessionId,
    );

    // 3. Backend Intelligence Call
    _ref.read(chatLoadingProvider.notifier).state = true;
    final startedSessionId = currentSessionId;

    try {
      // Step A: Update Gemini context on the fly
      final gemini = _ref.read(geminiServiceProvider);
      
      // Step B: Chat with Kelly and provide tool execution handlers
      final reply = await gemini.sendMessage(
        text: text,
        onToolCall: (call) async {
          if (call.name == 'add_academic_task') {
            final args = call.args;
            final title = args['title'] as String;
            final categoryStr = args['category'] as String;
            final dueDateStr = args['due_date'] as String;
            final desc = args['description'] as String?;
            
            var dueDate = DateTime.parse(dueDateStr);
            if (dueDate.isUtc) {
              dueDate = dueDate.toLocal();
            }
            // If Kelly provides no specific time (midnight), default to end of day so it doesn't instantly become overdue
            if (dueDate.hour == 0 && dueDate.minute == 0) {
              dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59);
            }
            
            final plannerNotifier = _ref.read(plannerProvider.notifier);
            await plannerNotifier.addTask(
              title: title,
              category: categoryStr,
              dueDate: dueDate,
              description: desc,
            );
            
            return {'status': 'success', 'message': 'Task added to planner'};
          }
          
          if (call.name == 'get_upcoming_tasks') {
            final dateStr = call.args['date'] as String;
            final date = DateTime.parse(dateStr);
            final tasks = _ref.read(plannerProvider).where((t) => 
               t.dueDate.year == date.year &&
               t.dueDate.month == date.month &&
               t.dueDate.day == date.day
            ).toList();
            
            return {
              'status': 'success', 
              'tasks': tasks.map((t) => {'title': t.title, 'category': t.category}).toList()
            };
          }
          
          return {'error': 'Tool not found'};
        }
      );

      if (_ref.read(currentSessionIdProvider) != startedSessionId) return;

      // 4. Success Path
      await LocalContextService.instance.persistMessage(
        content: reply,
        role: 'assistant',
        sessionId: startedSessionId,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        detectedEmotion: emotion,
      );

      _ref.read(chatLoadingProvider.notifier).state = false;
      state = [...state, aiMsg];

    } catch (e) {
      // 5. Offline / Timeout Fallback Path
      debugPrint('ChatFlow: Failed. Error: $e');
      
      if (_ref.read(currentSessionIdProvider) != startedSessionId) return;

      final snapshot = LocalContextService.instance.buildLocalSnapshot();
      final todayMood = snapshot['todayMood']?.toString().toLowerCase();
      
      String fallbackText = "I'm having a little trouble connecting to my internal wisdom right now... ";
      if (todayMood != null) {
        fallbackText += "but I'm still here for you. I noticed you're feeling $todayMood today—remember to be gentle with yourself. Let's keep talking once I'm back online! 🌟";
      } else {
        fallbackText += "but I'm still listening. Let's continue our chat as soon as my connection is stable! ✨";
      }

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: fallbackText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _ref.read(chatLoadingProvider.notifier).state = false;
      state = [...state, aiMsg];
    }
  }
}
