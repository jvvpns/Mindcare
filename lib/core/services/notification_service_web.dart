import 'package:flutter/foundation.dart';
import '../models/planner_entry.dart';
import 'notification_service.dart';

class WebNotificationService implements NotificationService {
  @override
  Future<void> init() async {
    debugPrint("Notification Service: Web implementation initialized (No-op).");
  }

  @override
  Future<void> setupDefaultReminders() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleDailySpark() async {}

  @override
  Future<void> scheduleRefuelReminders() async {}

  @override
  Future<void> scheduleEveningReflection() async {}

  @override
  Future<void> scheduleTaskReminder(PlannerEntry entry) async {}

  @override
  Future<void> cancelReminder(String id) async {}

  @override
  Future<void> scheduleDailyRefuelReminders() async {}

  @override
  Future<void> cancelAll() async {}
}

NotificationService getNotificationService() => WebNotificationService();
