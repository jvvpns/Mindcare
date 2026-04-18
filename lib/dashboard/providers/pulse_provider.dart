import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../../core/models/assessment_result.dart';
import '../../core/services/burnout_service.dart';

class PulseState {
  final double resilienceScore; // 0.0 (High Risk) to 1.0 (Stable)
  final String label;
  final BurnoutLevel level;
  final bool hasData;

  PulseState({
    required this.resilienceScore,
    required this.label,
    required this.level,
    this.hasData = true,
  });

  factory PulseState.initial() => PulseState(
        resilienceScore: 0.8, // Default "Healthy" state
        label: 'Start a Scan',
        level: BurnoutLevel.low,
        hasData: false,
      );
}

final wellnessPulseProvider = Provider<PulseState>((ref) {
  final assessmentBox = HiveService.assessmentBox;
  
  // Get latest burnout prediction
  final results = assessmentBox.values
      .where((r) => r.type == 'burnout_prediction')
      .toList()
    ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

  if (results.isEmpty) {
    return PulseState.initial();
  }

  final latest = results.first;
  
  // We use the interpretation to determine the level
  // AssessmentResult.interpretation looks like: 'Low Burnout Risk'
  final interpretation = latest.interpretation.toLowerCase();
  
  BurnoutLevel level = BurnoutLevel.low;
  double baseScore = 0.85; // Low risk default needle position

  if (interpretation.contains('high')) {
    level = BurnoutLevel.high;
    baseScore = 0.15; // Red zone
  } else if (interpretation.contains('medium')) {
    level = BurnoutLevel.medium;
    baseScore = 0.5; // Amber zone
  }

  // Adjust score slightly based on the 'totalScore' which stores the confidence %
  // This makes the needle feel "analogue" and precise.
  final confidence = latest.totalScore / 100.0;
  double adjustedScore = baseScore;
  
  if (level == BurnoutLevel.low) {
    // Higher confidence in low risk means even higher resilience
    adjustedScore = 0.7 + (confidence * 0.25);
  } else if (level == BurnoutLevel.high) {
    // Higher confidence in high risk means even lower resilience
    adjustedScore = 0.3 - (confidence * 0.25);
  }

  return PulseState(
    resilienceScore: adjustedScore.clamp(0.05, 0.95),
    label: latest.interpretation,
    level: level,
  );
});
