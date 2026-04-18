import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';

class HilwayErrorScreen extends StatelessWidget {
  final String? errorMessage;

  const HilwayErrorScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Icon ──────────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.crisis.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.warningCircle,
                    color: AppColors.crisis,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Title ─────────────────────────────────────────────────
              const Text(
                "Oops! Something went wrong.",
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Subtitle ──────────────────────────────────────────────
              Text(
                errorMessage ?? 
                "We couldn't find the page you were looking for. "
                "The nurses are looking into it!",
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // ── Action Button ─────────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back to Safety'),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'Sign in again',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
