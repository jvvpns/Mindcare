import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/planner_entry.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);
  }

  Future<void> scheduleTaskReminder(PlannerEntry entry) async {
    if (entry.reminderOffset == null || entry.isCompleted) return;

    final scheduleTime = entry.dueDate.subtract(Duration(minutes: entry.reminderOffset!));
    if (scheduleTime.isBefore(DateTime.now())) return; // Already passed

    final id = entry.id.hashCode;

    await _plugin.zonedSchedule(
      id: id,
      title: 'Upcoming: ${entry.title}',
      body: 'Starts in ${entry.reminderOffset} minutes',
      scheduledDate: tz.TZDateTime.from(scheduleTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hilway_reminders',
          'Academic Reminders',
          channelDescription: 'Reminders for clinical duties and exams',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String entryId) async {
    await _plugin.cancel(id: entryId.hashCode);
  }
}
