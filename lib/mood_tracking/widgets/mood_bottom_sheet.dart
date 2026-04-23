import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../providers/mood_provider.dart';

class MoodBottomSheet extends ConsumerStatefulWidget {
  final int initialMoodIndex;

  const MoodBottomSheet({super.key, required this.initialMoodIndex});

  static Future<void> show(BuildContext context, int moodIndex) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodBottomSheet(initialMoodIndex: moodIndex),
    );
  }

  @override
  ConsumerState<MoodBottomSheet> createState() => _MoodBottomSheetState();
}

class _MoodBottomSheetState extends ConsumerState<MoodBottomSheet> {
  late int _selectedMood;
  double _stressLevel = 3;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMoodIndex;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    final note = _noteController.text.trim();
    
    await ref.read(todayMoodProvider.notifier).logMoodAndStress(
          moodIndex: _selectedMood,
          moodLabel: AppConstants.moodLabels[_selectedMood],
          stressRating: _stressLevel.round(),
          note: note.isEmpty ? null : note,
        );

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    String title;
    final slot = getCurrentMoodSlot();
    switch (slot) {
      case MoodSlot.morning:
        title = "Morning Check-in";
        break;
      case MoodSlot.evening:
        title = "Evening Reflection";
        break;
      default:
        title = "How are you feeling?";
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              title,
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Emoji Selector Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(
                  AppConstants.moodEmojis.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMood = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedMood == index
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedMood == index
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              AppConstants.moodAnimatedAssets[index],
                              width: 44,
                              height: 44,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppConstants.moodLabels[index],
                              style: AppTextStyles.caption.copyWith(
                                color: _selectedMood == index
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: _selectedMood == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              "Stress level (1-5)",
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Stress Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.1),
                trackHeight: 8,
              ),
              child: Slider(
                value: _stressLevel,
                min: 1,
                max: 5,
                divisions: 4,
                label: _stressLevel.round().toString(),
                onChanged: (val) => setState(() => _stressLevel = val),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Very Low", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                Text("Very High", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),

            const SizedBox(height: 24),

            // Notes field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Add a little note (optional)...",
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 12),
            
            // ── Journal Nudge ───────────────────────────────────────────────
            TextButton.icon(
              onPressed: () {
                context.pop(); // Close sheet
                context.push('/journal/new'); // Go to journal
              },
              icon: PhosphorIcon(PhosphorIconsRegular.book, size: 18),
              label: Text(
                "Write more in your Journal", 
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
