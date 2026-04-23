import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../providers/chat_tutorial_provider.dart';

class ChatTutorialOverlay extends ConsumerWidget {
  const ChatTutorialOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: GestureDetector(
        // Prevent taps from falling through to the chat UI below
        onTap: () {},
        child: Container(
          color: AppColors.background.withValues(alpha: 0.85),
          child: HilwayGlass(
            sigmaX: 5,
            sigmaY: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.9, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: child,
                      );
                    },
                    child: _buildCard(context, ref),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const PhosphorIcon(
              PhosphorIconsRegular.handWaving,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),

          // Greeting
          const Text(
            "Hi, I'm Kelly",
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            "Your Nursing Student companion. I'm here to listen, support, and help you navigate the ups and downs of nursing school.",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Example Prompts Header
          Text(
            "Kelly reacts to your mood! Try typing these to unlock helpful shortcut buttons:",
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildExampleChip('"I feel stressed" ➔ Breathing Tool'),
              _buildExampleChip('"I\'m feeling [mood]" ➔ Mood Tracker'),
              _buildExampleChip('"I haven\'t eaten" ➔ Refuel Chart'),
              _buildExampleChip('"I feel overwhelmed" ➔ Crisis Support'),
            ],
          ),
          const SizedBox(height: 32),

          // Security Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(PhosphorIconsRegular.lockKey, size: 16, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Text(
                "You don't need perfect words—just be yourself.\nChats are 100% private and stored locally.",
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // CTA
          ElevatedButton(
            onPressed: () {
              ref.read(chatTutorialProvider.notifier).completeTutorial();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Start Chatting', style: AppTextStyles.buttonLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
