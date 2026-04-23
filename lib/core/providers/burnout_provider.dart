import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/burnout_risk.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../../clinical_duty/providers/shift_provider.dart';
import '../../core/providers/health_provider.dart';
import '../../dashboard/providers/refuel_provider.dart';
import '../services/intelligence_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/progress_provider.dart';
import '../../planner/providers/planner_provider.dart';
import '../../self_assessment/providers/self_assessment_provider.dart';
import '../../core/services/hive_service.dart';
import 'package:flutter/foundation.dart';

/// Provider for the calculated burnout risk using the TFLite model.
final burnoutRiskProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sleepHours = ref.watch(sleepDurationProvider);
  final todayMood = ref.watch(todayMoodProvider);
  final shiftTasks = ref.watch(shiftProvider);
  final refuelLog = ref.watch(refuelProvider);
  final lastManual = ref.watch(lastAssessmentProvider);
  final userId = ref.watch(authProvider).user?.id ?? 'anonymous';
  
  // 1. Map mood to base stress level (1.0 - 5.0)
  double moodStress = 3.0; // Default Neutral
  if (todayMood != null) {
    final mood = todayMood.moodLabel.toLowerCase();
    if (mood == 'calm') moodStress = 1.0;
    else if (mood == 'happy') moodStress = 2.0;
    else if (mood == 'energetic') moodStress = 2.0;
    else if (mood == 'neutral') moodStress = 3.0;
    else if (mood == 'anxious') moodStress = 4.0;
    else if (mood == 'sad') moodStress = 4.5;
    else if (mood == 'depressed') moodStress = 5.0;
  }

  // 2. Retrieve today's manual stress rating
  final now = DateTime.now();
  final stressLogs = HiveService.stressBox.values.where((log) => 
      log.userId == userId &&
      log.loggedAt.year == now.year &&
      log.loggedAt.month == now.month &&
      log.loggedAt.day == now.day);
      
  int? userStressRating;
  if (stressLogs.isNotEmpty) {
    userStressRating = stressLogs.reduce((a, b) => a.loggedAt.isAfter(b.loggedAt) ? a : b).rating;
  }

  // 3. Combine them (give manual rating 70% weight if available)
  double finalStress = moodStress;
  if (userStressRating != null) {
    finalStress = (moodStress * 0.3) + (userStressRating * 0.7);
  }

  // 4. Convert to moodTrend (0.0 to 1.0) for the backend API
  // Backend expects: input_stress = 5.0 - (moodTrend * 4.0)
  final moodTrend = ((5.0 - finalStress) / 4.0).clamp(0.0, 1.0);

  // 5. Total Workload (Academic + Clinical)
  double clinicalDuties = shiftTasks.where((t) => !t.isDone).length.toDouble();
  double academicTasks = ref.watch(plannerProvider).where((t) => !t.isCompleted).length.toDouble();
  
  // Weight clinical duties higher (1.5x) due to physical/emotional toll
  double totalWorkload = academicTasks + (clinicalDuties * 1.5);
  
  // Assume 12 equivalent tasks is a heavy "maximum" load
  final taskLoadIndex = (totalWorkload / 12.0).clamp(0.0, 1.0);

  // 6. Meals skipped
  double mealsSkipped = refuelLog?.missedMeals.toDouble() ?? 0.0;

  final features = {
    "mood_trend_score": moodTrend,
    "sleep_avg_hours": sleepHours > 0 ? sleepHours : 7.0,
    "task_load_index": taskLoadIndex,
    "burnout_history_score": 0.5,
    "meal_skip_rate": mealsSkipped / 3.0,
  };

  try {
    // ── Pre-flight: Check for very recent manual assessment (last 4 hours) ──
    // If a user just took a formal test, the Gauge should respect that 
    // manual "clinical" data over the heuristic pulse.
    if (lastManual != null) {
      final hoursSince = DateTime.now().difference(lastManual.takenAt).inHours;
      if (hoursSince < 4) {
        return {
          'level': _mapStringToLevel(lastManual.interpretation.split(' ').first),
          'confidence': lastManual.totalScore,
          'is_local': true,
          'is_manual_override': true,
        };
      }
    }

    final result = await IntelligenceService.instance.retry(() => 
      IntelligenceService.instance.predictBurnout(
        sleepHours: features['sleep_avg_hours'] as double,
        moodTrend: features['mood_trend_score'] as double,
        taskLoad: features['task_load_index'] as double,
        mealSkipRate: features['meal_skip_rate'] as double,
        userId: userId,
      ).timeout(const Duration(seconds: 15))
    );

    return {
      'level': _mapStringToLevel(result['level']),
      'confidence': result['confidence'],
      'is_local': false,
    };
  } catch (e) {
    // ── Offline Fallback: Use last known cached result ─────────────────────
    debugPrint('BurnoutProvider: Backend unavailable, using last cached result. Error: $e');
    
    final assessments = HiveService.assessmentBox.values
        .where((a) => a.type == 'burnout_prediction')
        .toList();
    
    if (assessments.isNotEmpty) {
      assessments.sort((a, b) => b.takenAt.compareTo(a.takenAt));
      final latest = assessments.first;
      
      return {
        'level': _mapStringToLevel(latest.interpretation),
        'confidence': latest.totalScore,
        'is_local': true,
        'timestamp': latest.takenAt,
      };
    }

    return {
      'level': BurnoutLevel.low,
      'confidence': 0.0,
      'is_local': true,
      'error': 'Offline and no cached data.',
    };
  }
});

BurnoutLevel _mapStringToLevel(String? level) {
  switch (level?.toLowerCase()) {
    case 'high': return BurnoutLevel.high;
    case 'medium': return BurnoutLevel.medium;
    default: return BurnoutLevel.low;
  }
}
