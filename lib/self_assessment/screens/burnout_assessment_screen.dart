import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hilway/core/constants/app_colors.dart';
import 'package:hilway/core/constants/app_text_styles.dart';
import 'package:hilway/self_assessment/providers/self_assessment_provider.dart';
import 'package:hilway/shared/widgets/hilway_background.dart';
import 'package:hilway/shared/widgets/hilway_card.dart';
import 'package:hilway/shared/widgets/responsive_wrapper.dart';

class BurnoutAssessmentScreen extends ConsumerWidget {
  const BurnoutAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answers = ref.watch(assessmentAnswersProvider);
    final evaluationState = ref.watch(assessmentStateProvider);
    final cooldown = ref.watch(burnoutCooldownProvider).value ?? Duration.zero;

    // Safety redirect if in cooldown — but only if we AREN'T currently seeing a result
    // or actively loading one. This prevents the "kick-out" bug during save.
    if (cooldown > Duration.zero && !evaluationState.hasValue && !evaluationState.isLoading) {
      Future.microtask(() {
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      });
    }

    // Watch evaluation state to navigate when complete
    ref.listen(assessmentStateProvider, (previous, next) {
      if (next.hasValue && next.value != null && !next.isLoading) {
        context.push('/burnout-result');
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HilwayBackground(
        emotion: 'calm',
        child: SafeArea(
          child: ResponsiveWrapper(
            child: evaluationState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        title: const Text('Burnout Assessment', style: AppTextStyles.headingSmall),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/dashboard');
                            }
                          },
                        ),
                        floating: true,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(24.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            HilwayCard(
                              isGlass: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Let\'s check in on how you\'re doing.',
                                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Phase 1: Physical Vitals',
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
  
                                  // Question 1: Sleep
                                  _buildQuestionLabel('1. Average sleep hours per night this week?'),
                                  Slider(
                                    value: answers.sleepHours,
                                    min: 0,
                                    max: 12,
                                    divisions: 12,
                                    label: "${answers.sleepHours.toInt()} hours",
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(sleepHours: val);
                                    },
                                  ),
                                  const SizedBox(height: 24),
  
                                  // Question 2: Clinical Duties (Intensity)
                                  _buildQuestionLabel('2. How many high-intensity shifts (ER, ICU, etc.) did you have this week?'),
                                  Slider(
                                    value: answers.duties,
                                    min: 0,
                                    max: 5,
                                    divisions: 5,
                                    label: "${answers.duties.toInt()} shifts",
                                    activeColor: AppColors.error,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(duties: val);
                                    },
                                  ),
                                  const SizedBox(height: 24),
  
                                  // Question 3: Meals
                                  _buildQuestionLabel('3. On average, how many meals do you skip a day?'),
                                  Slider(
                                    value: answers.mealsSkipped,
                                    min: 0,
                                    max: 4,
                                    divisions: 4,
                                    label: "${answers.mealsSkipped.toInt()}",
                                    activeColor: Colors.orange,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(mealsSkipped: val);
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Phase 2: Emotional Vitals',
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
  
                                  // Question 4: Dread
                                  _buildQuestionLabel('4. How often did you feel a sense of dread or anxiety before your shift? (1 = Never, 5 = Always)'),
                                  Slider(
                                    value: answers.dreadLevel,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: "${answers.dreadLevel.toInt()}",
                                    activeColor: AppColors.secondary,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(dreadLevel: val);
                                    },
                                  ),
                                  const SizedBox(height: 24),
  
                                  // Question 5: Compassion Fatigue
                                  _buildQuestionLabel('5. I feel like I am making a meaningful difference in my patients\' lives. (1 = Strongly Disagree, 5 = Strongly Agree)'),
                                  Slider(
                                    value: answers.compassionLevel,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: "${answers.compassionLevel.toInt()}",
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(compassionLevel: val);
                                    },
                                  ),
                                  const SizedBox(height: 24),
  
                                  // Question 6: Physical Tension
                                  _buildQuestionLabel('6. How much physical tension (headaches, back pain) are you carrying? (1 = None, 5 = Extreme)'),
                                  Slider(
                                    value: answers.physicalTension,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: "${answers.physicalTension.toInt()}",
                                    activeColor: Colors.purple,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(physicalTension: val);
                                    },
                                  ),
                                  const SizedBox(height: 24),
  
                                  // Question 7: General Stress
                                  _buildQuestionLabel('7. Rate your overall baseline stress level this week. (1 = Low, 5 = Extreme)'),
                                  Slider(
                                    value: answers.stressLevel,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: "${answers.stressLevel.toInt()}",
                                    activeColor: AppColors.error,
                                    onChanged: (val) {
                                      ref.read(assessmentAnswersProvider.notifier).state =
                                          answers.copyWith(stressLevel: val);
                                    },
                                  ),
  
                                  const SizedBox(height: 48),
  
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ref.read(assessmentStateProvider.notifier).evaluateAndSave(answers);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Analyze Risk',
                                        style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Text(
        text,
        style: AppTextStyles.buttonLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
