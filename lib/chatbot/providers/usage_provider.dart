import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';

class UsageState {
  final int messagesRemaining;
  final DateTime lastReset;

  UsageState({
    required this.messagesRemaining,
    required this.lastReset,
  });

  UsageState copyWith({
    int? messagesRemaining,
    DateTime? lastReset,
  }) =>
      UsageState(
        messagesRemaining: messagesRemaining ?? this.messagesRemaining,
        lastReset: lastReset ?? this.lastReset,
      );
}

class UsageNotifier extends StateNotifier<UsageState> {
  UsageNotifier()
      : super(UsageState(
          messagesRemaining: AppConstants.maxDailyMessages,
          lastReset: DateTime.now(),
        )) {
    _init();
  }

  void _init() {
    final settings = HiveService.settingsBox;
    final lastResetStr = settings.get(AppConstants.keyLastUsageReset) as String?;
    final count = settings.get(AppConstants.keyDailyUsageCount, defaultValue: 0) as int;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastResetStr == null) {
      // First time use
      _reset(today);
    } else {
      final lastResetDate = DateTime.parse(lastResetStr);
      final lastResetDay = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);

      if (today.isAfter(lastResetDay)) {
        // New day! Reset
        _reset(today);
      } else {
        // Same day, load remaining
        state = UsageState(
          messagesRemaining: AppConstants.maxDailyMessages - count,
          lastReset: lastResetDate,
        );
      }
    }
  }

  void _reset(DateTime date) {
    HiveService.settingsBox.put(AppConstants.keyLastUsageReset, date.toIso8601String());
    HiveService.settingsBox.put(AppConstants.keyDailyUsageCount, 0);
    
    state = UsageState(
      messagesRemaining: AppConstants.maxDailyMessages,
      lastReset: date,
    );
  }

  bool incrementUsage() {
    if (state.messagesRemaining <= 0) return false;

    final newCount = (AppConstants.maxDailyMessages - state.messagesRemaining) + 1;
    HiveService.settingsBox.put(AppConstants.keyDailyUsageCount, newCount);

    state = state.copyWith(messagesRemaining: state.messagesRemaining - 1);
    return true;
  }
}

final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  return UsageNotifier();
});
