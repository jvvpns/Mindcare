import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';

class NotificationPermissionNotifier extends StateNotifier<bool> {
  NotificationPermissionNotifier() : super(false) {
    _load();
  }

  void _load() {
    state = HiveService.settingsBox.get(
      AppConstants.keyHasEnabledNotifications,
      defaultValue: false,
    ) as bool;
  }

  Future<void> toggle(bool enabled) async {
    if (enabled) {
      // Trigger system permission prompt
      final granted = await NotificationService.instance.requestPermissions();
      if (granted) {
        state = true;
        await HiveService.settingsBox.put(AppConstants.keyHasEnabledNotifications, true);
        await NotificationService.instance.setupDefaultReminders();
      } else {
        // User denied at the system level
        state = false;
      }
    } else {
      // Turn off locally
      state = false;
      await HiveService.settingsBox.put(AppConstants.keyHasEnabledNotifications, false);
      await NotificationService.instance.cancelAll();
    }
  }
}

final notificationPermissionProvider = StateNotifierProvider<NotificationPermissionNotifier, bool>((ref) {
  return NotificationPermissionNotifier();
});
