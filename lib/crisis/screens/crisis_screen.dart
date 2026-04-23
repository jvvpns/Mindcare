import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/philippines_schools.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/hilway_background.dart';
import '../../shared/widgets/hilway_card.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../../shared/widgets/responsive_wrapper.dart';

class CrisisScreen extends ConsumerWidget {
  const CrisisScreen({super.key});

  Future<void> _makeCall(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number.replaceAll(' ', '').replaceAll('-', '').replaceAll('+', ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userSchoolName = authState.user?.userMetadata?['school'] as String?;
    
    // Find matching school info
    final schoolInfo = AppSchools.capizNursingSchools.where(
      (s) => s.name == userSchoolName
    ).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HilwayBackground(
        child: ResponsiveWrapper(
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 80, bottom: 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildEmergencyHeader(),
                      const SizedBox(height: 40),

                    // ── School Specific Support ─────────────────────────────
                    if (schoolInfo != null) ...[
                      _buildSectionHeader('Your School Support'),
                      _buildHotlineCard(
                        context,
                        title: schoolInfo.supportContact,
                        number: 'Contact via Office',
                        logoPath: schoolInfo.logoUrl,
                        subtitle: schoolInfo.name,
                      ),
                      const SizedBox(height: 16),
                      _buildHotlineCard(
                        context,
                        title: 'Affiliated Hospital',
                        number: schoolInfo.affiliatedHospital,
                        icon: PhosphorIconsRegular.hospital,
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    _buildSectionHeader('City Mental Health Helpline'),
                    _buildHotlineCard(
                      context,
                      title: 'KaEstorya Line (Globe)',
                      number: '0966 493 1178',
                      icon: PhosphorIconsRegular.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildHotlineCard(
                      context,
                      title: 'KaEstorya Line (Smart)',
                      number: '0985 384 3678',
                      icon: PhosphorIconsRegular.phone,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('National Crisis Hotlines'),
                    _buildHotlineCard(
                      context,
                      title: 'NCMH Crisis (Landline)',
                      number: '1553',
                      icon: PhosphorIconsRegular.phoneCall,
                    ),
                    const SizedBox(height: 16),
                    _buildHotlineCard(
                      context,
                      title: 'NCMH Crisis (Mobile)',
                      number: '0966 351 4518',
                      icon: PhosphorIconsRegular.phone,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('In Touch Community Services'),
                    _buildHotlineCard(
                      context,
                      title: 'Support Line (24/7)',
                      number: '0917 899 8727',
                      icon: PhosphorIconsRegular.phone,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              ),

              // ── Glassmorphic AppBar ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HilwayGlass(
                  sigmaX: 12,
                  sigmaY: 12,
                  child: Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                          ),
                          const Text('Crisis Support', style: AppTextStyles.headingSmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.crisis.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.crisis.withValues(alpha: 0.2)),
          ),
          child: const PhosphorIcon(PhosphorIconsFill.firstAid, size: 48, color: AppColors.crisis),
        ),
        const SizedBox(height: 24),
        const Text('You are not alone.', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'If you are in immediate danger or need someone to talk to, these services are available 24/7 in Roxas City and nationwide.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineCard(BuildContext context, {
    required String title, 
    required String number, 
    IconData? icon, 
    String? logoPath,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: HilwayCard(
        isGlass: true,
        glowColor: AppColors.crisis.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(16),
        onTap: () {
          if (number.contains('0') || number.length < 5) {
             _makeCall(number);
          }
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.crisis.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: logoPath != null 
                ? ClipOval(child: Image.asset(logoPath, fit: BoxFit.contain))
                : icon != null ? PhosphorIcon(icon, color: AppColors.crisis, size: 24) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    number, 
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crisis.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const PhosphorIcon(PhosphorIconsFill.phoneCall, color: AppColors.crisis, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}