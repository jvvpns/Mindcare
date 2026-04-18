import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';

// Provides the user's current daily streak based on mood logs
final streakProvider = StateProvider<int>((ref) {
  try {
    final moodLogs = HiveService.moodBox.values.toList();
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
      // If there are multiple entries on the same day (should be handled by Set/normalization, but just in case), skip
    }
    
    return streak;
  } catch (e) {
    return 0;
  }
});
