import 'package:hive/hive.dart';

part 'mood_log.g.dart';

@HiveType(typeId: 0)
class MoodLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final int moodIndex; // 0=Sad, 1=Stressed, 2=Neutral, 3=Calm, 4=Motivated

  @HiveField(3)
  final String moodLabel;

  @HiveField(4)
  final DateTime loggedAt;

  @HiveField(5)
  final String? note;

  MoodLog({
    required this.id,
    required this.userId,
    required this.moodIndex,
    required this.moodLabel,
    required this.loggedAt,
    this.note,
  });

  // ── Supabase ──────────────────────────────────────────────────────────────
  factory MoodLog.fromMap(Map<String, dynamic> map) => MoodLog(
    id:        map['id'] as String,
    userId:    map['user_id'] as String,
    moodIndex: map['mood_index'] as int,
    moodLabel: map['mood_label'] as String,
    loggedAt:  DateTime.parse(map['logged_at'] as String),
    note:      map['note'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id':         id,
    'user_id':    userId,
    'mood_index': moodIndex,
    'mood_label': moodLabel,
    'logged_at':  loggedAt.toIso8601String(),
    'note':       note,
  };

  MoodLog copyWith({
    String? id,
    String? userId,
    int? moodIndex,
    String? moodLabel,
    DateTime? loggedAt,
    String? note,
  }) =>
      MoodLog(
        id:        id ?? this.id,
        userId:    userId ?? this.userId,
        moodIndex: moodIndex ?? this.moodIndex,
        moodLabel: moodLabel ?? this.moodLabel,
        loggedAt:  loggedAt ?? this.loggedAt,
        note:      note ?? this.note,
      );

  @override
  String toString() =>
      'MoodLog(id: $id, mood: $moodLabel, loggedAt: $loggedAt)';
}