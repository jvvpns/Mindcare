import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/planner_entry.dart';
import 'notification_service.dart';
import 'dart:math';

class IONotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );

    await setupDefaultReminders();
  }

  @override
  Future<void> setupDefaultReminders() async {
    await cancelAll();
    await scheduleDailySpark();
    await scheduleRefuelReminders();
    await scheduleEveningReflection();
  }

  @override
  Future<bool> requestPermissions() async {
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    return result ?? false;
  }

  @override
  Future<void> scheduleDailySpark() async {
    final quotes = [
      "Small acts of care ripple into waves of healing.",
      "You are more than your shift. You are a guiding star.",
      "Today, focus on one patient's smile.",
      "Resilience is built one breath at a time.",
      "Your compassion is your greatest clinical tool.",
    ];
    final randomQuote = quotes[Random().nextInt(quotes.length)];

    await _scheduleDaily(
      id: 100,
      title: "Morning Spark ✨",
      body: randomQuote,
      hour: 7,
      minute: 0,
    );
  }

  @override
  Future<void> scheduleRefuelReminders() async {
    await _scheduleDaily(
      id: 200,
      title: "Refuel Reminder 🍎",
      body: "Time for a quick break. Have you had water or a meal yet?",
      hour: 11,
      minute: 30,
    );

    await _scheduleDaily(
      id: 201,
      title: "Refuel Reminder 🍲",
      body: "Duty or study can wait. Your body needs energy. Time to eat!",
      hour: 18,
      minute: 30,
    );
  }

  @override
  Future<void> scheduleEveningReflection() async {
    await _scheduleDaily(
      id: 300,
      title: "Evening Reflection 🌙",
      body: "How was your duty today? Log your mood now to maintain your daily streak before midnight!",
      hour: 20,
      minute: 0,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hilway_daily',
          'Daily Reminders',
          channelDescription: 'Daily check-ins and refuel reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> scheduleTaskReminder(PlannerEntry entry) async {
    final now = DateTime.now();
    if (entry.dueDate.isBefore(now)) return;

    final reminderTime = entry.dueDate.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(now)) return;

    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      entry.id.hashCode,
      "Task Deadline 📚",
      "Your task '${entry.title}' is due in 1 hour.",
      tzReminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hilway_planner',
          'Academic Planner',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelReminder(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }

  @override
  Future<void> scheduleDailyRefuelReminders() async {
    await scheduleRefuelReminders();
  }

  @override
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

NotificationService getNotificationService() => IONotificationService();
