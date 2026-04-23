import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/hilway_background.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../../shared/widgets/hilway_card.dart';
import '../../shared/widgets/responsive_wrapper.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../../chatbot/providers/kelly_state_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final moodLogs = ref.watch(moodLogsProvider);
    final journals = ref.watch(journalProvider);
    
    final now = DateTime.now();
    
    // Data for selected date
    final selectedMood = moodLogs.cast<dynamic>().where((l) => _isSameDay(l.loggedAt, _selectedDate)).firstOrNull;
    final selectedJournals = journals.where((j) => _isSameDay(j.createdAt, _selectedDate)).toList();
    final effectiveEmotion = ref.watch(globalBackgroundEmotionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HilwayBackground(
        emotion: effectiveEmotion,
        child: Stack(
          children: [
            // ── Premium Glass Header ─────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HilwayGlass(
                sigmaX: 12,
                sigmaY: 12,
                child: Container(
                    color: Colors.white.withValues(alpha: 0.1),
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
                    child: const Center(
                      child: Text('Mood Journey', style: AppTextStyles.headingSmall),
                    ),
                  ),
                ),
            ),

            ResponsiveWrapper(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Interactive Date Strip (The Ribbon) ─────────────────────
                      const SizedBox(height: 10),
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(7, (index) {
                              final day = now.subtract(Duration(days: 6 - index));
                              final isSelected = _isSameDay(day, _selectedDate);
                              final hasLog = moodLogs.any((l) => _isSameDay(l.loggedAt, day));
  
                              return Padding(
                                padding: EdgeInsets.only(right: index == 6 ? 0 : 12.0),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedDate = day),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: 56,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.primary 
                                          : Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        )
                                      ] : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateFormat('E').format(day).toUpperCase(),
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: isSelected ? Colors.white : AppColors.textTertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          day.day.toString(),
                                          style: AppTextStyles.headingSmall.copyWith(
                                            color: isSelected ? Colors.white : AppColors.textPrimary,
                                            fontSize: 18,
                                          ),
                                        ),
                                        if (hasLog)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Image.asset(
                                              AppConstants.moodAnimatedAssets[moodLogs.firstWhere((l) => _isSameDay(l.loggedAt, day)).moodIndex],
                                              width: 18,
                                              height: 18,
                                            ),
                                          )
                                        else
                                          Container(
                                            margin: const EdgeInsets.only(top: 6),
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.white : AppColors.primary.withValues(alpha: 0.4),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
  
                      const SizedBox(height: 32),
                      
                      // ── Day Summary Section ─────────────────────────────────────
                      Text(
                        _isSameDay(_selectedDate, now) ? "Today's Summary" : DateFormat('MMMM d, y').format(_selectedDate),
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(height: 12),
                      
                      HilwayCard(
                        isGlass: true,
                        glowColor: selectedMood != null ? AppColors.primary : Colors.transparent,
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            if (selectedMood != null) ...[
                              Image.asset(
                                AppConstants.moodAnimatedAssets[selectedMood.moodIndex],
                                width: 64,
                                height: 64,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Feeling ${selectedMood.moodLabel}",
                                      style: AppTextStyles.headingSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.wb_sunny_outlined, size: 48, color: AppColors.textTertiary),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("No mood logged", style: AppTextStyles.headingSmall),
                                    const SizedBox(height: 4),
                                    Text("Take a moment to check in.", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
  
                      const SizedBox(height: 32),
                      
                      // ── Reflections Section ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("DAILY REFLECTIONS", style: AppTextStyles.labelSmall),
                          if (selectedJournals.isNotEmpty)
                            Text(
                              "${selectedJournals.length} entries",
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (selectedJournals.isEmpty)
                        HilwayCard(
                          isGlass: true,
                          color: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                PhosphorIcon(PhosphorIconsRegular.pencilSimpleLine, color: AppColors.textTertiary.withValues(alpha: 0.5), size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  "No journal entries for this day.",
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...selectedJournals.map((entry) => GestureDetector(
                          onTap: () => context.push('/journal/edit', extra: entry),
                          child: HilwayCard(
                            isGlass: true,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            glowColor: AppColors.secondary.withValues(alpha: 0.3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const PhosphorIcon(PhosphorIconsRegular.quotes, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.title,
                                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  entry.content,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        )),
  
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}