import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/mood_log.dart';
import '../../core/services/hive_service.dart';
import '../providers/streak_provider.dart';

class StreakDetailsSheet extends ConsumerStatefulWidget {
  final int streakCount;
  final List<bool> weeklyActivity;

  const StreakDetailsSheet({
    super.key,
    required this.streakCount,
    required this.weeklyActivity,
  });

  static void show(BuildContext context, int streakCount, List<bool> weeklyActivity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreakDetailsSheet(
        streakCount: streakCount,
        weeklyActivity: weeklyActivity,
      ),
    );
  }

  @override
  ConsumerState<StreakDetailsSheet> createState() => _StreakDetailsSheetState();
}

class _StreakDetailsSheetState extends ConsumerState<StreakDetailsSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getMotivationalMessage() {
    if (widget.streakCount == 0) {
      return "Start your wellness journey today. Log your mood to build your streak!";
    } else if (widget.streakCount < 3) {
      return "Great start! Come back tomorrow to keep your streak going.";
    } else if (widget.streakCount < 7) {
      return "You're on a roll! Keep up the daily check-ins.";
    } else {
      return "Incredible consistency! Your dedication to your well-being is inspiring.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStreak = widget.streakCount > 0;
    final graceTokens = ref.watch(streakMetadataProvider);
    
    // Check for milestones whenever the sheet is viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakMetadataProvider.notifier).checkMilestone(widget.streakCount);
    });

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40), // Balance
              Text(
                "Streak",
                style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.x, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Animated Plant Icon
          ScaleTransition(
            scale: hasStreak ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: hasStreak 
                      ? [AppColors.success.withValues(alpha: 0.8), AppColors.success]
                      : [AppColors.textTertiary.withValues(alpha: 0.3), AppColors.textTertiary.withValues(alpha: 0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: hasStreak ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 8,
                  )
                ] : null,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsFill.plant,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Count-up Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: widget.streakCount.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                "${value.toInt()} Day Streak!",
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Restore Button (PWA Optimized)
          if (!hasStreak && graceTokens > 0) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showRestoreDialog(context),
                icon: const PhosphorIcon(PhosphorIconsFill.magicWand, color: Colors.white, size: 20),
                label: const Text("Restore My Streak", style: AppTextStyles.buttonLarge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You have $graceTokens Grace Token${graceTokens > 1 ? 's' : ''} available.",
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],

          // Weekly Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isCompleted = widget.weeklyActivity[index];
              final isToday = DateTime.now().weekday - 1 == index;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.success : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted ? AppColors.success : AppColors.borderLight,
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Center(child: PhosphorIcon(PhosphorIconsBold.check, color: Colors.white, size: 16))
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          
          // Motivational Message
          Text(
            _getMotivationalMessage(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Wellness Grace", style: AppTextStyles.headingSmall),
        content: const Text(
          "Do you want to use 1 Grace Token to restore your streak? \n\n"
          "This will fill in yesterday's missing log and bring back your progress.",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Not Now", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performRestore();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Restore", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
    HapticFeedback.mediumImpact();
    
    // 1. Consume Token
    await ref.read(streakMetadataProvider.notifier).useToken();
    
    // 2. Insert Ghost Log for Yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final moodLog = MoodLog(
      id: "restore_${DateTime.now().millisecondsSinceEpoch}",
      userId: "local", // Should ideally be fetched from auth
      moodIndex: 0, // Calm
      moodLabel: "Restored",
      loggedAt: yesterday,
      note: "Streak restored using Wellness Grace.",
    );
    
    await HiveService.moodBox.put(moodLog.id, moodLog);
    
    // 3. Close Sheet (it will update Dashboard automatically via reactivity)
    if (mounted) Navigator.pop(context);
    
    // Show success snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Streak Restored! ✨ Keep up the consistency."),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
