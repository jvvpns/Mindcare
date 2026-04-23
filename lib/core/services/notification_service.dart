import 'package:flutter/foundation.dart';
import '../models/planner_entry.dart';
import 'dart:math';

// Conditional imports are used to avoid compilation errors on Web/Chrome
// while maintaining full functionality on Mobile.
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_io.dart'
    if (dart.library.html) 'notification_service_web.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';

abstract class NotificationService {
  static NotificationService get instance => getNotificationService();

  Future<void> init();
  Future<void> setupDefaultReminders();
  Future<bool> requestPermissions();
  Future<void> scheduleDailySpark();
  Future<void> scheduleRefuelReminders();
  Future<void> scheduleEveningReflection();
  Future<void> scheduleTaskReminder(PlannerEntry entry);
  Future<void> cancelReminder(String id);
  Future<void> scheduleDailyRefuelReminders();
  Future<void> cancelAll();
}
