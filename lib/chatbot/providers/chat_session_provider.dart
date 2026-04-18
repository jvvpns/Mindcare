import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/chat_session.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/gemini_service.dart';

/// Tracks the active session ID. Null means "New/Unsaved Chat".
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

/// Interacts with the Hive box for chat sessions.
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>(
  (ref) => ChatSessionsNotifier(ref),
);

class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  final Ref _ref;
  final _uuid = const Uuid();

  ChatSessionsNotifier(this._ref) : super([]) {
    _loadSessions();
  }

  void _loadSessions() {
    final box = HiveService.chatSessionBox;
    final sessions = box.values.toList();
    // Sort descending by updated at
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = sessions;
  }

  Future<ChatSession> createSession(String initialText) async {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await HiveService.chatSessionBox.put(newSession.id, newSession);
    _ref.read(currentSessionIdProvider.notifier).state = newSession.id;
    
    // Auto-generate title in background
    _generateTitle(newSession.id, initialText);
    
    _loadSessions();
    return newSession;
  }

  Future<void> _generateTitle(String sessionId, String firstMessage) async {
    try {
      final prompt = 'Summarize this user message in 3-4 words for a chat title. Only return the title, no quotes or intro: "$firstMessage"';
      final geminiService = _ref.read(Provider((ref) => GeminiService())); // Read directly to avoid cycle if any
      final title = await geminiService.sendMessage(text: prompt);
      
      final cleanTitle = title.replaceAll('"', '').trim();
      if (cleanTitle.isNotEmpty) {
        final session = HiveService.chatSessionBox.get(sessionId);
        if (session != null) {
          final updatedSession = session.copyWith(title: cleanTitle);
          await HiveService.chatSessionBox.put(sessionId, updatedSession);
          _loadSessions();
        }
      }
    } catch (_) {
      // Ignore failures
    }
  }

  Future<void> updateSessionTime(String sessionId) async {
    final session = HiveService.chatSessionBox.get(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(updatedAt: DateTime.now());
      await HiveService.chatSessionBox.put(sessionId, updatedSession);
      _loadSessions();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    // 1. Delete session
    await HiveService.chatSessionBox.delete(sessionId);

    // 2. Delete all messages with this sessionId
    final box = HiveService.chatBox;
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final msg = box.get(key);
      if (msg != null && msg.sessionId == sessionId) {
        keysToDelete.add(key);
      }
    }
    
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    _loadSessions();
    
    // If the active session is deleted, reset it
    if (_ref.read(currentSessionIdProvider) == sessionId) {
      _ref.read(currentSessionIdProvider.notifier).state = null;
    }
  }

  Future<void> deleteAllSessions() async {
    await HiveService.chatSessionBox.clear();
    await HiveService.chatBox.clear();
    _loadSessions();
    _ref.read(currentSessionIdProvider.notifier).state = null;
  }
}
