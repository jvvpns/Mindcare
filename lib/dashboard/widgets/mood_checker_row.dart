import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/hilway_card.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../../mood_tracking/widgets/mood_bottom_sheet.dart';

class MoodCheckerRow extends ConsumerWidget {
  const MoodCheckerRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLog = ref.watch(todayMoodProvider);
    final slot = getCurrentMoodSlot();

    String title;
    if (todayLog != null) {
      title = "You're feeling ${todayLog.moodLabel}";
    } else {
      switch (slot) {
        case MoodSlot.morning:
          title = "Morning Check-in: Ready for today?";
          break;
        case MoodSlot.evening:
          title = "Evening Reflection: How was your day?";
          break;
        default:
          title = "How are you feeling right now?";
      }
    }

    return HilwayCard(
      isGlass: true,
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final count = AppConstants.moodEmojis.length;

              // On wider screens, distribute evenly; on compact, scroll
              final isWide = availableWidth >= 380;

              // Scale item size proportionally to available width
              final itemSize = isWide
                  ? ((availableWidth - 16) / count).clamp(44.0, 72.0)
                  : 52.0;
              final iconSize = itemSize * 0.68;
              final spacing = isWide ? 0.0 : 12.0;

              Widget buildItem(int index) {
                final isSelected = todayLog != null && todayLog.moodIndex == index;
                return GestureDetector(
                  onTap: () {
                    if (todayLog == null) MoodBottomSheet.show(context, index);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: itemSize,
                        height: itemSize,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(itemSize * 0.3),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppConstants.moodAnimatedAssets[index],
                            width: iconSize,
                            height: iconSize,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppConstants.moodLabels[index],
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: isWide ? 11 : 10,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (isWide) {
                // Tablet / Desktop: distribute items evenly using Expanded to prevent text overflow
                return Row(
                  children: List.generate(count, (i) => Expanded(child: buildItem(i))),
                );
              } else {
                // Mobile: horizontal scroll with fixed spacing
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      count,
                      (i) => Padding(
                        padding: EdgeInsets.only(right: i < count - 1 ? spacing : 0),
                        child: buildItem(i),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

