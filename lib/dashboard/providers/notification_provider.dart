import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum NotificationType { insight, alert, achievement, system }

class InAppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  InAppNotification copyWith({bool? isRead}) {
    return InAppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<InAppNotification>> {
  NotificationNotifier() : super([]) {
    _loadInitial();
  }

  void _loadInitial() {
    // For now, let's seed with some contextual examples for the user to see
    state = [
      InAppNotification(
        id: const Uuid().v4(),
        title: "Morning Spark Archive",
        message: "Small acts of care ripple into waves of healing. You're doing great!",
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.insight,
      ),
      InAppNotification(
        id: const Uuid().v4(),
        title: "Resilience Streak",
        message: "You've logged your mood for 3 days straight. Keep it up! 🌱",
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.achievement,
      ),
    ];
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) {
    final notification = InAppNotification(
      id: const Uuid().v4(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void clearAll() {
    state = [];
  }
}

final inAppNotificationProvider = StateNotifierProvider<NotificationNotifier, List<InAppNotification>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(inAppNotificationProvider).where((n) => !n.isRead).length;
});
