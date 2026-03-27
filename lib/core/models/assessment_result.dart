import 'package:hive/hive.dart';

part 'assessment_result.g.dart';

enum AssessmentType { pss10, burnout, sus, tam }

@HiveType(typeId: 4)
class AssessmentResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String type; // 'pss10' | 'burnout' | 'sus' | 'tam'

  @HiveField(3)
  final double totalScore;

  @HiveField(4)
  final Map<String, dynamic> answers; // raw question → answer map

  @HiveField(5)
  final String interpretation; // e.g. 'Low Stress', 'Moderate Burnout'

  @HiveField(6)
  final DateTime takenAt;

  AssessmentResult({
    required this.id,
    required this.userId,
    required this.type,
    required this.totalScore,
    required this.answers,
    required this.interpretation,
    required this.takenAt,
  });

  // ── PSS-10 Interpretation ─────────────────────────────────────────────────
  static String interpretPss10(double score) {
    if (score <= 13) return 'Low stress';
    if (score <= 26) return 'Moderate stress';
    return 'High perceived stress';
  }

  // ── SUS Interpretation ────────────────────────────────────────────────────
  static String interpretSus(double score) {
    if (score > 80.3) return 'Excellent';
    if (score >= 68)  return 'Good';
    if (score >= 51)  return 'Poor';
    return 'Awful';
  }

  // ── TAM Interpretation ────────────────────────────────────────────────────
  static String interpretTam(double score) {
    if (score <= 19) return 'Low acceptance';
    if (score <= 31) return 'Moderate acceptance';
    return 'High acceptance';
  }

  // ── Supabase ──────────────────────────────────────────────────────────────
  factory AssessmentResult.fromMap(Map<String, dynamic> map) =>
      AssessmentResult(
        id:             map['id'] as String,
        userId:         map['user_id'] as String,
        type:           map['type'] as String,
        totalScore:     (map['total_score'] as num).toDouble(),
        answers:        Map<String, dynamic>.from(map['answers'] as Map),
        interpretation: map['interpretation'] as String,
        takenAt:        DateTime.parse(map['taken_at'] as String),
      );

  Map<String, dynamic> toMap() => {
    'id':             id,
    'user_id':        userId,
    'type':           type,
    'total_score':    totalScore,
    'answers':        answers,
    'interpretation': interpretation,
    'taken_at':       takenAt.toIso8601String(),
  };

  AssessmentResult copyWith({
    String? id,
    String? userId,
    String? type,
    double? totalScore,
    Map<String, dynamic>? answers,
    String? interpretation,
    DateTime? takenAt,
  }) =>
      AssessmentResult(
        id:             id ?? this.id,
        userId:         userId ?? this.userId,
        type:           type ?? this.type,
        totalScore:     totalScore ?? this.totalScore,
        answers:        answers ?? this.answers,
        interpretation: interpretation ?? this.interpretation,
        takenAt:        takenAt ?? this.takenAt,
      );

  @override
  String toString() =>
      'AssessmentResult(type: $type, score: $totalScore, interpretation: $interpretation)';
}