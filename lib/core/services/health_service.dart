import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Manages synchronization with Apple Health (iOS) and Health Connect (Android).
/// Currently focused on iOS Sleep data for efficient first-step implementation.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();

  /// The list of health data types HILWAY is interested in.
  static final List<HealthDataType> _types = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.MINDFULNESS, // For breathing exercises
  ];

  /// Request authorization from the user.
  /// Should be called from a UI toggle or onboarding.
  Future<bool> requestAuthorization() async {
    try {
      // Android specific: Check for Health Connect app
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          // If not installed, we can prompt to install
          await _health.installHealthConnect();
          return false;
        }
      }

      // Request permissions
      bool requested = await _health.requestAuthorization(_types);
      return requested;
    } catch (e) {
      debugPrint('HealthService: Authorization failed — $e');
      return false;
    }
  }

  /// Fetches the total hours of sleep for the last 24 hours.
  /// Returns 0.0 if no data is found or permission is denied.
  Future<double> getRecentSleepDuration() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      if (healthData.isEmpty) return 0.0;

      // Sum up all sleep segments in the last 24h
      double totalMinutes = 0;
      for (var point in healthData) {
        // Sleep data points are typically intervals
        final duration = point.dateTo.difference(point.dateFrom);
        totalMinutes += duration.inMinutes;
      }

      return totalMinutes / 60.0; // Return hours
    } catch (e) {
      debugPrint('HealthService: Failed to fetch sleep data — $e');
      return 0.0;
    }
  }

  /// Logs a mindfulness session (e.g., after a breathing exercise).
  Future<bool> logMindfulnessSession(int minutes) async {
    final now = DateTime.now();
    final startTime = now.subtract(Duration(minutes: minutes));

    try {
      return await _health.writeHealthData(
        value: minutes.toDouble(),
        type: HealthDataType.MINDFULNESS,
        startTime: startTime,
        endTime: now,
      );
    } catch (e) {
      debugPrint('HealthService: Failed to log mindfulness — $e');
      return false;
    }
  }
}
