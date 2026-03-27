import 'package:hive/hive.dart';

part 'stress_rating.g.dart';

@HiveType(typeId: 1)
class StressRating extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final int rating; // 1 (very low) – 5 (very high)

  @HiveField(3)
  final DateTime loggedAt;

  @HiveField(4)
  final String? note;

  StressRating({
    required this.id,
    required this.userId,
    required this.rating,
    required this.loggedAt,
    this.note,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get ratingLabel {
    switch (rating) {
      case 1: return 'Very low';
      case 2: return 'Low';
      case 3: return 'Moderate';
      case 4: return 'High';
      case 5: return 'Very high';
      default: return 'Unknown';
    }
  }

  bool get isHighStress => rating >= 4;

  // ── Supabase ──────────────────────────────────────────────────────────────
  factory StressRating.fromMap(Map<String, dynamic> map) => StressRating(
    id:       map['id'] as String,
    userId:   map['user_id'] as String,
    rating:   map['rating'] as int,
    loggedAt: DateTime.parse(map['logged_at'] as String),
    note:     map['note'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id':        id,
    'user_id':   userId,
    'rating':    rating,
    'logged_at': loggedAt.toIso8601String(),
    'note':      note,
  };

  StressRating copyWith({
    String? id,
    String? userId,
    int? rating,
    DateTime? loggedAt,
    String? note,
  }) =>
      StressRating(
        id:       id ?? this.id,
        userId:   userId ?? this.userId,
        rating:   rating ?? this.rating,
        loggedAt: loggedAt ?? this.loggedAt,
        note:     note ?? this.note,
      );

  @override
  String toString() =>
      'StressRating(id: $id, rating: $rating, loggedAt: $loggedAt)';
}