import '../../core/models/burnout_risk.dart';
import '../../core/providers/sync_provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/mood_log.dart';
import '../../core/models/planner_entry.dart';
import '../../clinical_duty/models/shift_task.dart';
import '../../chatbot/widgets/kelly_orb_mascot.dart';
import '../providers/dashboard_interaction_provider.dart';
import '../providers/streak_provider.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../../core/providers/health_provider.dart';
import '../../clinical_duty/providers/shift_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/kelly_insight_provider.dart';
import 'notification_drawer.dart';
import 'streak_details_sheet.dart';

class DashboardHeader extends ConsumerWidget {
  final String userName;
  final String quote;
  final String effectiveEmotion;
  final BurnoutLevel? burnoutLevel;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.quote,
    required this.effectiveEmotion,
    this.burnoutLevel,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Logic moved to KellyInsightProvider for performance

  Color _getKellyCardColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'default':
      case 'energetic':
        return AppColors.emotionToColors['happy']![0].withValues(alpha: 0.85);
      case 'happy':
        return AppColors.emotionToColors['concerned']![0].withValues(alpha: 0.85);
      case 'calm':
        return AppColors.emotionToColors['sad']![0].withValues(alpha: 0.85);
      case 'sad':
        return AppColors.emotionToColors['calm']![0].withValues(alpha: 0.85);
      case 'excited':
        return AppColors.emotionToColors['surprised']![0].withValues(alpha: 0.85);
      case 'concerned':
        return AppColors.emotionToColors['happy']![0].withValues(alpha: 0.85);
      case 'surprised':
        return AppColors.emotionToColors['excited']![0].withValues(alpha: 0.85);
      default:
        return AppColors.emotionToColors['happy']![0].withValues(alpha: 0.85);
    }
  }

  Color _getKellyCardBorderColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'default':
      case 'energetic':
        return AppColors.emotionToColors['happy']![1].withValues(alpha: 0.4);
      case 'happy':
        return AppColors.emotionToColors['concerned']![1].withValues(alpha: 0.4);
      case 'calm':
        return AppColors.emotionToColors['sad']![1].withValues(alpha: 0.4);
      case 'sad':
        return AppColors.emotionToColors['calm']![1].withValues(alpha: 0.4);
      case 'excited':
        return AppColors.emotionToColors['surprised']![1].withValues(alpha: 0.4);
      case 'concerned':
        return AppColors.emotionToColors['happy']![1].withValues(alpha: 0.4);
      case 'surprised':
        return AppColors.emotionToColors['excited']![1].withValues(alpha: 0.4);
      default:
        return AppColors.emotionToColors['happy']![1].withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakCount = ref.watch(streakProvider);
    final weeklyActivity = ref.watch(weeklyActivityProvider);
    final pokedMessage = ref.watch(kellyPokedMessageProvider);
    final insightMessage = ref.watch(kellyInsightProvider);
    final syncStatus = ref.watch(syncStatusProvider).value ?? SyncUIState.idle;
    
    final message = pokedMessage ?? insightMessage;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── App Brand & Tagline ───────────────────────────────────
        RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/hilway_logo.png', height: 28),
                    const SizedBox(width: 10),
                    Text(
                      "HILWAY",
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  "Holistic Inner Life Well-being and AI for You",
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_greeting(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _capitalize(userName),
                    style: AppTextStyles.displayMedium.copyWith(
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF4DB6AC), Color(0xFF9575CD)],
                        ).createShader(const Rect.fromLTWH(0.0, 0.0, 220.0, 70.0)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
              Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    StreakDetailsSheet.show(context, streakCount, weeklyActivity);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsFill.plant, color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Text('$streakCount', style: AppTextStyles.labelMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: _buildSyncIcon(syncStatus),
                ),
                const SizedBox(width: 8),
                _NotificationBell(ref: ref),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!isDesktop) // Only show the full card on Mobile/Tablet
          GestureDetector(
          onTap: () => ref.read(kellyPokedMessageProvider.notifier).poke(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Builder(
                builder: (context) {
                  final bgColor = _getKellyCardColor(effectiveEmotion);
                  final borderColor = _getKellyCardBorderColor(effectiveEmotion);
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Glowing Orb (No separate background circle) ─────────
                        RepaintBoundary(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Center(
                              child: KellyMiniOrb(emotion: effectiveEmotion, size: 54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // ── Message Content ──────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Kelly",
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: AppColors.primary, 
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),
          ),
        ) else // On Desktop, show a compact "Clinical Pulse" bar instead
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsFill.lightning, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSyncIcon(SyncUIState state) {
    switch (state) {
      case SyncUIState.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
        );
      case SyncUIState.pending:
        return const PhosphorIcon(PhosphorIconsRegular.cloudArrowUp, color: AppColors.textTertiary, size: 20);
      case SyncUIState.error:
        return const PhosphorIcon(PhosphorIconsFill.cloudWarning, color: AppColors.crisis, size: 20);
      case SyncUIState.idle:
        return const PhosphorIcon(PhosphorIconsRegular.cloudCheck, color: AppColors.success, size: 20);
    }
  }
}

class _NotificationBell extends StatelessWidget {
  final WidgetRef ref;
  const _NotificationBell({required this.ref});

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        NotificationDrawer.show(context);
        ref.read(inAppNotificationProvider.notifier).markAllAsRead();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const PhosphorIcon(PhosphorIconsRegular.bell, color: AppColors.textPrimary, size: 20),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.crisis,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
