import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hilway/core/services/hive_service.dart';
import 'package:hilway/core/models/chat_message.dart' as hive_msg;

/// Responsible for:
/// 1. Building a plain-text summary of user health data (system prompt injection).
/// 2. Reconstructing Gemini Content history from persisted Hive messages.
/// 3. Persisting new chat messages to Hive after each exchange.
class KellyContextService {
  KellyContextService._();
  static final KellyContextService instance = KellyContextService._();

  // Reduced from 30→15 for faster token processing and better efficiency at scale
  static const int _maxHistoryMessages = 15;

  // ── 1. User Context Summary (System Prompt Part) ─────────────────────────
  String buildUserContextSummary() {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln('=== System Context ===');
    buffer.writeln('Current Date: ${DateFormat('EEEE, MMMM d, yyyy').format(now)}');
    buffer.writeln('Current Time: ${DateFormat('h:mm a').format(now)}');
    buffer.writeln('\n=== User Health Context ===');

    // Recent moods (last 7 entries)
    try {
      final moods = HiveService.moodBox.values.toList();
      if (moods.isNotEmpty) {
        moods.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
        final recent = moods.take(7).toList();
        final labels = recent.map((m) => m.moodLabel).join(', ');
        buffer.writeln('Recent moods (newest first): $labels');
      } else {
        buffer.writeln('Mood: No mood logs recorded yet.');
      }
    } catch (_) {
      buffer.writeln('Mood: (unavailable)');
    }

    // Latest burnout assessment
    try {
      final assessments = HiveService.assessmentBox.values
          .where((a) => a.type == 'burnout_prediction')
          .toList();
      if (assessments.isNotEmpty) {
        assessments.sort((a, b) => b.takenAt.compareTo(a.takenAt));
        final latest = assessments.first;
        final dateStr = DateFormat('MMM d, yyyy').format(latest.takenAt);
        buffer.writeln(
          'Burnout Assessment ($dateStr): ${latest.interpretation} '
          '(confidence: ${latest.totalScore.toStringAsFixed(1)}%)',
        );
      } else {
        buffer.writeln('Burnout Assessment: None taken yet.');
      }
    } catch (_) {
      buffer.writeln('Burnout Assessment: (unavailable)');
    }

    // Recent Journal Entries
    try {
      final journals = HiveService.journalBox.values.toList();
      if (journals.isNotEmpty) {
        journals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentJournals = journals.take(3).toList();
        buffer.writeln('Recent Journal Entries:');
        for (final entry in recentJournals) {
          final dateStr = DateFormat('MMM d').format(entry.createdAt);
          buffer.writeln('- [$dateStr] ${entry.title}: "${entry.content}"');
        }
      } else {
        buffer.writeln('Journal: No recent entries.');
      }
    } catch (_) {
      buffer.writeln('Journal: (unavailable)');
    }

    // Today's mood check — so Kelly won't ask again if already logged
    try {
      final now = DateTime.now();
      final todayMoods = HiveService.moodBox.values.where((m) =>
          m.loggedAt.year == now.year &&
          m.loggedAt.month == now.month &&
          m.loggedAt.day == now.day);
      if (todayMoods.isNotEmpty) {
        final todayLabel = todayMoods.first.moodLabel;
        buffer.writeln('Today\'s mood: Already checked in. Feeling "$todayLabel" today. Do NOT ask the user how they are feeling today — they\'ve already told you.');
      } else {
        buffer.writeln('Today\'s mood: Not yet logged. You may gently ask how they are feeling today if relevant.');
      }
    } catch (_) {
      // non-fatal
    }

    // Upcoming Academic Planner Tasks
    try {
      final now = DateTime.now();
      final upcomingTasks = HiveService.plannerBox.values
          .where((t) => t.dueDate.isAfter(now.subtract(const Duration(days: 1))) && !t.isCompleted)
          .toList();
      if (upcomingTasks.isNotEmpty) {
        upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final topTasks = upcomingTasks.take(5).toList();
        buffer.writeln('Upcoming Academic Tasks:');
        for (final task in topTasks) {
          final dateStr = DateFormat('MMM d').format(task.dueDate);
          buffer.writeln('- [${task.category}] ${task.title} (Due: $dateStr)');
        }
      } else {
        buffer.writeln('Academic Planner: No pending upcoming tasks right now.');
      }
    } catch (_) {
      buffer.writeln('Academic Planner: (unavailable)');
    }

    buffer.writeln('=== End Context ===');
    return buffer.toString();
  }

  // ── 2. Chat History for Gemini ────────────────────────────────────────────
  List<Content> buildChatHistory({int limit = _maxHistoryMessages, String? sessionId}) {
    try {
      final allMessages = HiveService.chatBox.values.toList();
      if (allMessages.isEmpty) return [];

      // Filter by session ID if provided
      final sessionMessages = sessionId != null 
          ? allMessages.where((m) => m.sessionId == sessionId).toList() 
          : allMessages;

      if (sessionMessages.isEmpty) return [];

      sessionMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      final recent = sessionMessages.length > limit
          ? sessionMessages.sublist(sessionMessages.length - limit)
          : sessionMessages;

      return recent.map((msg) {
        // Gemini SDK uses 'model' for assistant, 'user' for user
        final geminiRole = msg.role == 'user' ? 'user' : 'model';
        return Content(geminiRole, [TextPart(msg.content)]);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 3. Persist Messages ───────────────────────────────────────────────────
  Future<void> persistMessage({
    required String content,
    required String role, // 'user' or 'assistant'
    bool isCrisisDetected = false,
    String? sessionId,
  }) async {
    try {
      final msg = hive_msg.ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: role,
        sentAt: DateTime.now(),
        isCrisisDetected: isCrisisDetected,
        sessionId: sessionId,
      );
      await HiveService.chatBox.add(msg);
    } catch (_) {
      // Non-fatal — don't crash the chat if persistence fails
    }
  }

  // ── 4. Convenience: Today's Mood Label ───────────────────────────────────
  /// Returns the mood label string if the user has logged their mood today,
  /// or null if they haven't. Used by the chat provider to build Kelly's
  /// context-aware greeting so she doesn't repeat "How are you feeling?".
  String? getTodayMood(DateTime now) {
    try {
      final todayMoods = HiveService.moodBox.values.where((m) =>
          m.loggedAt.year == now.year &&
          m.loggedAt.month == now.month &&
          m.loggedAt.day == now.day);
      if (todayMoods.isNotEmpty) {
        return todayMoods.first.moodLabel;
      }
    } catch (_) {
      // non-fatal
    }
    return null;
  }
}
