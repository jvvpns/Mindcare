import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/sync_service.dart';

// Provides the user's current daily streak based on mood logs
// Provides the user's current daily streak based on mood logs
// Optimized for PWA: Watches the box stream for instant UI updates
final streakProvider = StateProvider<int>((ref) {
  final moodBox = HiveService.moodBox;
  
  // Create a listener that refreshes this provider whenever the box changes
  final subscription = moodBox.watch().listen((_) {
    // Force a re-computation of the streak logic
    ref.invalidateSelf();
  });

  ref.onDispose(() => subscription.cancel());

  try {
    final moodLogs = moodBox.values.toList();
    if (moodLogs.isEmpty) return 0;

    // Extract unique dates of mood logs (normalized to midnight)
    final uniqueDates = moodLogs.map((log) {
      return DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
    }).toSet().toList();

    // Sort descending (newest first)
    uniqueDates.sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // If the last log is older than yesterday, the streak is lost.
    if (uniqueDates.isEmpty || uniqueDates.first.isBefore(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime dateToCheck = uniqueDates.first == today ? today : yesterday;

    for (final loggedDate in uniqueDates) {
      if (loggedDate.isAtSameMomentAs(dateToCheck)) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      } else if (loggedDate.isBefore(dateToCheck)) {
        // Gap detected
        break;
      }
    }

    // Milestone Reward Logic: For every 14 days, check if we should grant a Grace Token
    // This is handled in a separate provider or effect to avoid side effects in build
    
    return streak;
  } catch (e) {
    return 0;
  }
});

/// Tracks available 'Wellness Grace' restore tokens in Hive/Supabase
final streakMetadataProvider = StateNotifierProvider<StreakMetadataNotifier, int>((ref) {
  return StreakMetadataNotifier();
});

class StreakMetadataNotifier extends StateNotifier<int> {
  StreakMetadataNotifier() : super(0) {
    _load();
  }

  void _load() {
    state = HiveService.settingsBox.get('streak_grace_tokens', defaultValue: 1);
  }

  Future<void> useToken() async {
    if (state > 0) {
      final newVal = state - 1;
      await HiveService.settingsBox.put('streak_grace_tokens', newVal);
      state = newVal;
      
      // Sync to Supabase for PWA persistence
      SyncService.instance.queueUpsert(
        table: 'settings',
        id: 'streak_metadata',
        data: {'streak_grace_tokens': newVal},
      );
    }
  }

  Future<void> addToken() async {
    final newVal = state + 1;
    await HiveService.settingsBox.put('streak_grace_tokens', newVal);
    state = newVal;
    
    SyncService.instance.queueUpsert(
      table: 'settings',
      id: 'streak_metadata',
      data: {'streak_grace_tokens': newVal},
    );
  }
  
  // Logic to grant token on 14-day milestones
  void checkMilestone(int currentStreak) {
    if (currentStreak > 0 && currentStreak % 14 == 0) {
      final lastRewarded = HiveService.settingsBox.get('last_streak_milestone', defaultValue: 0);
      if (currentStreak > lastRewarded) {
        addToken();
        HiveService.settingsBox.put('last_streak_milestone', currentStreak);
      }
    }
  }
}

/// Provides a List of 7 booleans representing Monday-Sunday of the current week.
/// True means a mood was logged on that day.
final weeklyActivityProvider = StateProvider<List<bool>>((ref) {
  final moodBox = HiveService.moodBox;
  
  // Watch the box for PWA reactivity
  final subscription = moodBox.watch().listen((_) => ref.invalidateSelf());
  ref.onDispose(() => subscription.cancel());

  try {
    final moodLogs = moodBox.values.toList();
    final now = DateTime.now();
    
    // Find the Monday of the current week
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    // Create a list of the 7 days of the current week
    final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    // Check if each day has a mood log
    return weekDays.map((day) {
      return moodLogs.any((log) => 
        log.loggedAt.year == day.year && 
        log.loggedAt.month == day.month && 
        log.loggedAt.day == day.day
      );
    }).toList();
  } catch (e) {
    return List.filled(7, false);
  }
});
