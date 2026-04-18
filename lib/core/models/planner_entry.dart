import 'package:hive/hive.dart';

part 'planner_entry.g.dart';

enum PlannerCategory { exam, clinicalDuty, returnDemo, todo, reminder }

@HiveType(typeId: 3)
class PlannerEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String category; // 'exam' | 'clinical_duty' | 'return_demo' | 'todo' | 'reminder'

  @HiveField(5)
  final DateTime dueDate;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? endTime;

  @HiveField(9)
  final int? reminderOffset; // Minutes before due date

  PlannerEntry({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.endTime,
    this.reminderOffset,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now());

  PlannerCategory get plannerCategory {
    switch (category) {
      case 'exam':         return PlannerCategory.exam;
      case 'clinical_duty': return PlannerCategory.clinicalDuty;
      case 'return_demo':  return PlannerCategory.returnDemo;
      case 'reminder':     return PlannerCategory.reminder;
      default:             return PlannerCategory.todo;
    }
  }

  // ── Supabase ──────────────────────────────────────────────────────────────
  factory PlannerEntry.fromMap(Map<String, dynamic> map) => PlannerEntry(
    id:          map['id'] as String,
    userId:      map['user_id'] as String,
    title:       map['title'] as String,
    description: map['description'] as String?,
    category:    map['category'] as String,
    dueDate:     DateTime.parse(map['due_date'] as String),
    isCompleted: map['is_completed'] as bool? ?? false,
    createdAt:   DateTime.parse(map['created_at'] as String),
    endTime:     map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
    reminderOffset: map['reminder_offset'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'id':           id,
    'user_id':      userId,
    'title':        title,
    'description':  description,
    'category':     category,
    'due_date':     dueDate.toIso8601String(),
    'is_completed': isCompleted,
    'created_at':   createdAt.toIso8601String(),
    'end_time':     endTime?.toIso8601String(),
    'reminder_offset': reminderOffset,
  };

  PlannerEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? endTime,
    int? reminderOffset,
  }) =>
      PlannerEntry(
        id:          id ?? this.id,
        userId:      userId ?? this.userId,
        title:       title ?? this.title,
        description: description ?? this.description,
        category:    category ?? this.category,
        dueDate:     dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt:   createdAt ?? this.createdAt,
        endTime:     endTime ?? this.endTime,
        reminderOffset: reminderOffset ?? this.reminderOffset,
      );

  @override
  String toString() =>
      'PlannerEntry(id: $id, title: $title, category: $category, due: $dueDate)';
}