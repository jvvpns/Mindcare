import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/providers/debug_provider.dart';
import '../../core/providers/health_provider.dart';
import '../../shared/widgets/hilway_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isDebugMode = ref.watch(debugModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: HilwayBackground(
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                      ),
                      child: const Center(
                        child: PhosphorIcon(PhosphorIconsRegular.user, size: 40, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email ?? 'Guiding Star',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nursing Student',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Preferences
              const Text('Preferences', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Platform.isIOS ? PhosphorIconsRegular.heartbeat : PhosphorIconsRegular.pulse,
                title: Platform.isIOS ? 'Sync Apple Health' : 'Sync Health Connect',
                subtitle: 'Connect sleep & mindfulness data',
                onTap: () async {
                  final authorized = await ref.read(sleepDurationProvider.notifier).authorizeAndFetch();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authorized ? 'Health Data Synced!' : 'Sync failed or denied.'),
                        backgroundColor: authorized ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                trailing: const Icon(PhosphorIconsRegular.caretRight, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: PhosphorIconsRegular.bell,
                title: 'Notifications',
                subtitle: 'Reminders for duty & reflection',
                onTap: () {},
                trailing: Switch(
                  value: true,
                  onChanged: (val) {},
                  activeThumbColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: PhosphorIconsRegular.moon,
                title: 'Dark Mode',
                subtitle: 'System Default',
                onTap: () {},
                trailing: const Icon(PhosphorIconsRegular.caretRight, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: PhosphorIconsRegular.bug,
                title: 'Debug Mode',
                subtitle: 'Developer diagnostic tools',
                onTap: () => ref.read(debugModeProvider.notifier).state = !isDebugMode,
                trailing: Switch(
                  value: isDebugMode,
                  onChanged: (val) => ref.read(debugModeProvider.notifier).state = val,
                  activeThumbColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),
              
              // Support
              const Text('Support', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: PhosphorIconsRegular.question,
                title: 'Help & FAQ',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: PhosphorIconsRegular.shieldCheck,
                title: 'Privacy Policy',
                onTap: () {},
              ),

              const SizedBox(height: 40),

              // Sign Out
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const PhosphorIcon(PhosphorIconsRegular.signOut, color: AppColors.error),
                  label: Text('Sign Out', style: AppTextStyles.buttonLarge.copyWith(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text(
                      'HILWAY v1.0.0',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Made with',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          PhosphorIconsFill.heart,
                          color: AppColors.error,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'for student nurses in',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roxas City, Capiz',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}