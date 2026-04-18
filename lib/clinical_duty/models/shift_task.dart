import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';

part 'shift_task.g.dart';

@HiveType(typeId: AppConstants.hiveTypeShiftTask)
class ShiftTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  bool isDone;

  @HiveField(4)
  final DateTime createdAt;

  ShiftTask({
    String? id,
    required this.title,
    required this.category,
    this.isDone = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  ShiftTask copyWith({
    String? title,
    String? category,
    bool? isDone,
  }) {
    return ShiftTask(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }
}
