import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/hilway_background.dart';
import '../providers/mood_provider.dart';

class MoodTrackingScreen extends ConsumerWidget {
  const MoodTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodLogs = ref.watch(moodLogsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mood Journey', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: HilwayBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Stats Summary ─────────────────────────────────────────────
              _buildStatsSummary(moodLogs),

              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'Recent Reflections',
                  style: AppTextStyles.headingSmall,
                ),
              ),

              // ── Mood History List ─────────────────────────────────────────
              Expanded(
                child: moodLogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: moodLogs.length,
                        itemBuilder: (context, index) {
                          final log = moodLogs[index];
                          return _buildMoodLogCard(log);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<dynamic> logs) {
    // Quick count of moods in last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentLogs = logs.where((l) => l.loggedAt.isAfter(sevenDaysAgo)).toList();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wellness Pulse',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    logs.isEmpty ? 'Waiting for your first log' : '${recentLogs.length} ${recentLogs.length == 1 ? 'log' : 'logs'} this week',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/images/pulse_wave.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Mini Mood Dots Visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = now.subtract(Duration(days: 6 - index));
              final dayLog = logs.cast<dynamic>().where((l) => 
                l.loggedAt.year == day.year && 
                l.loggedAt.month == day.month && 
                l.loggedAt.day == day.day
              ).firstOrNull;

              return Column(
                children: [
                  Text(
                    DateFormat('E').format(day)[0],
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: dayLog != null 
                          ? AppColors.primary.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: dayLog != null
                          ? Text(AppConstants.moodEmojis[dayLog.moodIndex], style: const TextStyle(fontSize: 16))
                          : Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle)),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodLogCard(dynamic log) {
    final date = DateFormat('MMM d • h:mm a').format(log.loggedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  AppConstants.moodEmojis[log.moodIndex],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.moodLabel,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              // Optional Stress Level indicator if available in future
              // (The model currently doesn't store stress rating in MoodLog, 
              // it's a separate StressRating model, but we can add it later)
            ],
          ),
          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIconsFill.quotes, color: AppColors.primary.withValues(alpha: 0.2), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.note!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryText.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.2,
              child: const Icon(PhosphorIconsFill.smileyBlank, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your journey starts here',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Once you log your first mood on the home screen, your patterns will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}