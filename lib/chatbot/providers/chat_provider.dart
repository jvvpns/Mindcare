import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/kelly_context_service.dart';
import '../../core/services/kelly_emotion_service.dart';
import 'kelly_state_provider.dart';
import 'chat_safety_provider.dart';
import 'chat_session_provider.dart';
import 'usage_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../planner/providers/planner_provider.dart';

/// Provides the singleton Gemini API handler.
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
      final contextService = KellyContextService.instance;
      final geminiService = _ref.read(geminiServiceProvider);

      // ── Part 1: System prompt (always injected) ─────────────────────────────
      final contextSummary = contextService.buildUserContextSummary();

      // ── Part 2: Gemini history — ONLY for saved sessions ────────────────────
      // New Chat → empty history. This is the efficiency fix: no token waste.
      final geminiHistory = sessionId != null
          ? contextService.buildChatHistory(sessionId: sessionId, limit: 15)
          : <Content>[];

      geminiService.startSessionWithContext(
        userContextSummary: contextSummary,
        history: geminiHistory,
      );

      // ── Part 3: UI messages ─────────────────────────────────────────────────
      if (sessionId != null) {
        // Reload the saved session's messages for display
        final hiveMessages = contextService.buildChatHistory(
          sessionId: sessionId,
          limit: 15,
        );
        final uiMessages = hiveMessages.map((content) {
          final isUser = content.role == 'user';
          final textContent = content.parts
              .map((p) => p is TextPart ? p.text : '')
              .where((t) => t.isNotEmpty)
              .join();
          return ChatMessage(
            id: _uuid.v4(),
            text: textContent,
            isUser: isUser,
            timestamp: DateTime.now(),
          );
        }).toList();
        state = uiMessages.isNotEmpty ? uiMessages : [_buildGreeting()];
      } else {
        // New Chat — always start fresh with a mood-aware greeting
        state = [_buildGreeting()];
      }
    } catch (e) {
      // Fallback: plain session with greeting
      _ref.read(geminiServiceProvider).startChat();
      state = [_buildGreeting()];
    } finally {
      _ref.read(chatInitializingProvider.notifier).state = false;
    }
  }

  /// Builds a context-aware greeting for Kelly.
  /// If the user already logged their mood today, she acknowledges it.
  /// Otherwise she asks how they're feeling.
  ChatMessage _buildGreeting() {
    String greetingText;
    try {
      final now = DateTime.now();
      final todayMoods = KellyContextService.instance.getTodayMood(now);
      if (todayMoods != null) {
        final mood = todayMoods.toLowerCase();
        greetingText =
            "Hey! I see you're feeling $mood today 😊 I'm right here if you want to talk about it, vent, or just need someone to listen.";
      } else {
        greetingText =
            "Hi there! I'm Kelly, your Nursing Student companion. I'm here if you need to vent about clinicals, stress, or just talk through your day. How are you feeling right now?";
      }
    } catch (_) {
      greetingText =
          "Hi there! I'm Kelly, your Nursing Student companion. I'm here if you need to vent about clinicals, stress, or just talk through your day. How are you feeling right now?";
    }
    return ChatMessage(
      id: 'init_${DateTime.now().millisecondsSinceEpoch}',
      text: greetingText,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }


  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Empathy Hook: Detect sentiment to animate Kelly mascot.
    final emotion = KellyEmotionService.detectEmotion(text);
    _ref.read(kellyEmotionProvider.notifier).state = emotion;

    // 1b. Safety Check: If crisis keywords are found, activate the persistent bar.
    if (KellyEmotionService.isCrisis(text)) {
      _ref.read(isCrisisActiveProvider.notifier).state = true;
    }

    // 1c. Session Check: Create a new session if none exists
    String? currentSessionId = _ref.read(currentSessionIdProvider);
    if (currentSessionId == null) {
      final sessionNotifier = _ref.read(chatSessionsProvider.notifier);
      final newSession = await sessionNotifier.createSession(text);
      currentSessionId = newSession.id;
    }

    // 2. Optimistic UI: Add user message instantly.
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      detectedEmotion: emotion,
    );
    state = [...state, userMsg];

    // 3. Persist user message to Hive.
    await KellyContextService.instance.persistMessage(
      content: text,
      role: 'user',
      sessionId: currentSessionId,
    );

    // Update Session Time
    await _ref.read(chatSessionsProvider.notifier).updateSessionTime(currentSessionId);

    // Check Usage Limits
    final usage = _ref.read(usageProvider);
    if (usage.messagesRemaining <= 0) {
      final restingMsg = ChatMessage(
        id: _uuid.v4(),
        text: "I'm taking a short rest to recharge so I can give you my best focus tomorrow. Let's talk again then! 💙",
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, restingMsg];
      return;
    }

    // 4. Show "Kelly is typing..."
    _ref.read(chatLoadingProvider.notifier).state = true;

    // 5. Get Gemini reply.
    final service = _ref.read(geminiServiceProvider);
    
    // Safety: Capture the session ID when we started.
    final startedSessionId = currentSessionId;

    final reply = await service.sendMessage(
      text: text,
      onToolCall: (call) async {
        // If the user switched sessions while we were waiting for Gemini,
        // abort the tool call to prevent state corruption.
        if (_ref.read(currentSessionIdProvider) != startedSessionId) {
          return {'status': 'error', 'message': 'session_changed'};
        }

        if (call.name == 'add_academic_task') {
          try {
            final args = call.args;
            final title = args['title'] as String;
            final category = args['category'] as String;
            final dueDateStr = args['due_date'] as String;
            final description = args['description'] as String?;

            final dueDate = DateTime.parse(dueDateStr);
            
            await _ref.read(plannerProvider.notifier).addTask(
              title: title,
              category: category,
              dueDate: dueDate,
              description: description,
            );
            
            return {'status': 'success', 'message': 'Task added to planner successfully.'};
          } catch (e) {
            return {'status': 'error', 'message': e.toString()};
          }
        } else if (call.name == 'get_upcoming_tasks') {
          try {
            final args = call.args;
            final dateStr = args['date'] as String;
            final queryDate = DateTime.parse(dateStr);
            
            final allTasks = _ref.read(plannerProvider);
            final dayTasks = allTasks.where((t) => 
              t.dueDate.year == queryDate.year && 
              t.dueDate.month == queryDate.month && 
              t.dueDate.day == queryDate.day
            ).toList();

            if (dayTasks.isEmpty) {
              return {'status': 'success', 'message': 'No tasks scheduled for this date.'};
            }

            final taskSummaries = dayTasks.map((t) {
              final timeStr = '${t.dueDate.hour}:${t.dueDate.minute.toString().padLeft(2, '0')}';
              final status = t.isCompleted ? 'Done' : 'Pending';
              return '${t.title} ($timeStr) - $status';
            }).toList();

            return {
              'status': 'success',
              'tasks': taskSummaries,
            };
          } catch (e) {
            return {'status': 'error', 'message': e.toString()};
          }
        }
        return {'status': 'error', 'message': 'unknown_function'};
      },
    );

    // If the user switched sessions during the API call, ignore the reply.
    if (_ref.read(currentSessionIdProvider) != startedSessionId) {
      _ref.read(chatLoadingProvider.notifier).state = false;
      return;
    }

    // Increment Usage Count
    _ref.read(usageProvider.notifier).incrementUsage();

    // 6. Persist Kelly's reply to Hive.
    await KellyContextService.instance.persistMessage(
      content: reply,
      role: 'assistant',
      sessionId: currentSessionId,
    );

    // Determine Contextual Action
    String? suggestedAction;
    if (emotion == AppConstants.kellyConcerned || emotion == AppConstants.kellySad || KellyEmotionService.isCrisis(text)) {
      suggestedAction = AppRoutes.breathing;
    }

    // 7. Publish AI message & clear loading.
    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
      detectedEmotion: emotion, // Pass emotion so the bubble renders the correct chathead
      suggestedAction: suggestedAction,
    );

    _ref.read(chatLoadingProvider.notifier).state = false;
    state = [...state, aiMsg];
  }
}
