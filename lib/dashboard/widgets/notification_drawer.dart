import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationDrawer extends ConsumerWidget {
  const NotificationDrawer({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationDrawer(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(inAppNotificationProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Insights & Updates", style: AppTextStyles.headingSmall),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(inAppNotificationProvider.notifier).clearAll(),
                    child: Text("Clear all", style: AppTextStyles.labelSmall.copyWith(color: AppColors.crisis)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _NotificationTile(notification: n);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(PhosphorIconsRegular.tray, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "All clear!",
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
          ),
          Text(
            "New insights will appear here.",
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final InAppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.insight:
        icon = PhosphorIconsFill.sparkle;
        color = AppColors.primary;
        break;
      case NotificationType.alert:
        icon = PhosphorIconsFill.warning;
        color = AppColors.crisis;
        break;
      case NotificationType.achievement:
        icon = PhosphorIconsFill.trophy;
        color = AppColors.success;
        break;
      case NotificationType.system:
        icon = PhosphorIconsFill.info;
        color = AppColors.accent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notification.title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('h:mm a').format(notification.timestamp),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
