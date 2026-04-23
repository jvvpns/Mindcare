import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/responsive_wrapper.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../../core/utils/device_utils.dart';
import '../providers/self_assessment_provider.dart';

class SelfAssessmentScreen extends ConsumerWidget {
  const SelfAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cooldownAsync = ref.watch(burnoutCooldownProvider);
    final lastResult = ref.watch(lastAssessmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wellness Tools', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Self-Assessment Suite',
                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your clinical resilience and burnout risk with medical-grade tools.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
  
              // ── Burnout Assessment Card ──────────────────────────────────────
              _buildAssessmentCard(
                context,
                title: 'AI Burnout Prediction',
                subtitle: 'Multi-factor analysis of your physical and emotional load.',
                icon: PhosphorIconsRegular.brain,
                color: AppColors.primary,
                cooldown: cooldownAsync.value ?? Duration.zero,
                onTap: () => context.push(AppRoutes.burnoutAssessment),
                lastResult: lastResult?.interpretation,
              ),
  
              const SizedBox(height: 16),
  
              // ── Placeholder for future assessments ───────────────────────────
              _buildAssessmentCard(
                context,
                title: 'Compassion Fatigue Scale',
                subtitle: 'Measure your empathy levels and emotional exhaustion.',
                icon: PhosphorIconsRegular.heartbeat,
                color: AppColors.secondary,
                isLocked: true,
                onTap: () {},
              ),
              
              const SizedBox(height: 16),
  
              _buildAssessmentCard(
                context,
                title: 'Anxiety Check (GAD-7)',
                subtitle: 'Clinical screening for general anxiety symptoms.',
                icon: PhosphorIconsRegular.chartLine,
                color: AppColors.error,
                isLocked: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Duration cooldown = Duration.zero,
    bool isLocked = false,
    String? lastResult,
  }) {
    final bool inCooldown = cooldown > Duration.zero;
    final bool disabled = isLocked || inCooldown;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: disabled ? AppColors.borderLight : Colors.white.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: DeviceUtils.isMobileWeb ? 5 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: HilwayGlass(
          borderRadius: BorderRadius.circular(24),
          sigmaX: 12,
          sigmaY: 12,
          child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: PhosphorIcon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: disabled ? AppColors.textTertiary : AppColors.textPrimary,
                              ),
                            ),
                            if (lastResult != null)
                              Text(
                                'Last: $lastResult',
                                style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      if (isLocked)
                        const PhosphorIcon(PhosphorIconsRegular.lock, color: AppColors.textTertiary, size: 20)
                      else if (inCooldown)
                        _buildCooldownBadge(cooldown)
                      else
                        const PhosphorIcon(PhosphorIconsRegular.caretRight, color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildCooldownBadge(Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhosphorIcon(PhosphorIconsRegular.clock, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '${hours}h ${minutes}m',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}