import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/mood_log.dart';
import '../../core/models/stress_rating.dart';
import '../../core/models/journal_entry.dart';
import '../../core/services/hive_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../journal/providers/journal_provider.dart';

// Provider that holds today's MoodLog if it exists
final todayMoodProvider = StateNotifierProvider<MoodNotifier, MoodLog?>((ref) {
  final userId = ref.watch(authProvider).user?.id ?? '';
  return MoodNotifier(userId, ref);
});

// Provider for all historical mood logs (sorted latest first)
final moodLogsProvider = Provider<List<MoodLog>>((ref) {
  final userId = ref.watch(authProvider).user?.id ?? '';
  if (userId.isEmpty) return [];

  return HiveService.moodBox.values
      .where((log) => log.userId == userId)
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
});

class MoodNotifier extends StateNotifier<MoodLog?> {
  final String userId;
  final Ref _ref;
  final _uuid = const Uuid();

  MoodNotifier(this.userId, this._ref) : super(null) {
    if (userId.isNotEmpty) _init();
  }

  void _init() {
    // Check if there is a mood log for today
    final now = DateTime.now();
    final logs = HiveService.moodBox.values.where((log) =>
        log.userId == userId &&
        log.loggedAt.year == now.year &&
        log.loggedAt.month == now.month &&
        log.loggedAt.day == now.day);
    
    if (logs.isNotEmpty) {
      // Get the latest log if multiple exist (should just be 1 normally)
      state = logs.reduce((a, b) => a.loggedAt.isAfter(b.loggedAt) ? a : b);
    }
  }

  Future<void> logMoodAndStress({
    required int moodIndex,
    required String moodLabel,
    required int stressRating,
    String? note,
  }) async {
    if (userId.isEmpty) return;

    final now = DateTime.now();
    
    // Create Mode Log
    final moodLog = MoodLog(
      id: _uuid.v4(),
      userId: userId,
      moodIndex: moodIndex,
      moodLabel: moodLabel,
      loggedAt: now,
      note: note,
    );

    // Create Stress Rating
    final stressLog = StressRating(
      id: _uuid.v4(),
      userId: userId,
      rating: stressRating,
      loggedAt: now,
      note: note,
    );

    // Save locally
    await HiveService.moodBox.put(moodLog.id, moodLog);
    await HiveService.stressBox.put(stressLog.id, stressLog);

    // Auto-create Journal Entry from Mood & Note
    final journalContent = StringBuffer();
    journalContent.write("A moment of $moodLabel. Stress level: $stressRating/5.");
    if (note != null && note.trim().isNotEmpty) {
      journalContent.write("\n\n${note.trim()}");
    }

    final journalEntry = JournalEntry.create(
      title: "Daily Reflection",
      content: journalContent.toString(),
      moodIndex: moodIndex.toDouble(),
    );
    await HiveService.journalBox.put(journalEntry.id, journalEntry);

    // Update state to reflect it instantly in the UI
    state = moodLog;

    // Invalidate journalProvider so the dashboard's "Daily Reflection" card
    // immediately shows the new entry without needing a restart.
    _ref.invalidate(journalProvider);

    // Phase 3: Sync to Supabase in background (omitted for now until tables exist)
  }
}
