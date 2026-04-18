import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_service.dart';

/// Provider for the current day's sleep duration in hours.
final sleepDurationProvider = StateNotifierProvider<SleepDurationNotifier, double>((ref) {
  return SleepDurationNotifier();
});

class SleepDurationNotifier extends StateNotifier<double> {
  SleepDurationNotifier() : super(0.0) {
    // We don't auto-fetch on init because it needs permission first.
  }

  /// Attempts to fetch sleep data. 
  /// Returns false if permission is needed.
  Future<void> refreshSleepData() async {
    final duration = await HealthService.instance.getRecentSleepDuration();
    state = duration;
  }

  /// Unified method to request permission and then fetch.
  Future<bool> authorizeAndFetch() async {
    final authorized = await HealthService.instance.requestAuthorization();
    if (authorized) {
      await refreshSleepData();
    }
    return authorized;
  }
}

/// Provider for whether HealthKit is currently authorized.
final healthAuthorizedProvider = StateProvider<bool>((ref) => false);
