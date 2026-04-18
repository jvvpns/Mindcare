import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/hilway_background.dart';

class CrisisScreen extends StatelessWidget {
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
      // Handle error (e.g. simulator)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crisis Support', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: HilwayBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const PhosphorIcon(PhosphorIconsFill.firstAid, size: 48, color: AppColors.error),
                ),
                const SizedBox(height: 24),
                const Text('You are not alone.', style: AppTextStyles.headingMedium),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'If you are in immediate danger or need someone to talk to, these services are available 24/7.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildSectionHeader('City Mental Health Helpline'),
                _buildHotlineCard(
                  context,
                  title: 'KaEstorya Line (Globe)',
                  number: '0966 493 1178',
                  icon: PhosphorIconsRegular.phone,
                ),
                const SizedBox(height: 12),
                _buildHotlineCard(
                  context,
                  title: 'KaEstorya Line (Smart)',
                  number: '0985 384 3678',
                  icon: PhosphorIconsRegular.phone,
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Crisis / Suicide Hotlines'),
                _buildHotlineCard(
                  context,
                  title: 'NCMH Crisis (Landline)',
                  number: '1553',
                  icon: PhosphorIconsRegular.phoneCall,
                ),
                const SizedBox(height: 12),
                _buildHotlineCard(
                  context,
                  title: 'NCMH Crisis (Globe)',
                  number: '0966 351 4518',
                  icon: PhosphorIconsRegular.phone,
                ),
                const SizedBox(height: 12),
                _buildHotlineCard(
                  context,
                  title: 'NCMH Crisis (Smart)',
                  number: '0917 899 8727',
                  icon: PhosphorIconsRegular.phone,
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('In Touch Community Services'),
                _buildHotlineCard(
                  context,
                  title: 'In Touch (Globe)',
                  number: '+63 917 800 1123',
                  icon: PhosphorIconsRegular.phone,
                ),
                const SizedBox(height: 12),
                _buildHotlineCard(
                  context,
                  title: 'In Touch (Smart)',
                  number: '+63 919 056 0709',
                  icon: PhosphorIconsRegular.phone,
                ),
                const SizedBox(height: 12),
                _buildHotlineCard(
                  context,
                  title: 'In Touch (Sun)',
                  number: '+63 922 893 8944',
                  icon: PhosphorIconsRegular.phone,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineCard(BuildContext context, {required String title, required String number, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: PhosphorIcon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(number, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          Material(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _makeCall(number),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: PhosphorIcon(PhosphorIconsFill.phoneCall, color: AppColors.error, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}