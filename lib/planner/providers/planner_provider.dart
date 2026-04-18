import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/planner_entry.dart';
import '../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, List<PlannerEntry>>((ref) {
  return PlannerNotifier(ref);
});

class PlannerNotifier extends StateNotifier<List<PlannerEntry>> {
  final Ref _ref;
  PlannerNotifier(this._ref) : super([]) {
    _load();
  }

  Box<PlannerEntry>? _box;

  Future<void> _load() async {
    _box = Hive.box<PlannerEntry>(AppConstants.boxPlannerEntries);
    state = _box!.values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> addTask({
    required String title,
    required String category,
    required DateTime dueDate,
    DateTime? endTime,
    int? reminderOffset,
    String? description,
  }) async {
    final user = _ref.read(authProvider).user;
    final entry = PlannerEntry(
      id: const Uuid().v4(),
      userId: user?.id ?? 'local',
      title: title,
      category: category,
      dueDate: dueDate,
      endTime: endTime,
      reminderOffset: reminderOffset,
      description: description,
      createdAt: DateTime.now(),
      isCompleted: false,
    );
    await _box?.put(entry.id, entry);
    await NotificationService.instance.scheduleTaskReminder(entry);
    _refresh();
  }

  Future<void> toggleDone(String id) async {
    final entry = _box?.get(id);
    if (entry == null) return;
    
    // PlannerEntry fields are final in the existing model, so we copyWith
    final updated = entry.copyWith(isCompleted: !entry.isCompleted);
    await _box?.put(id, updated);
    
    if (updated.isCompleted) {
      await NotificationService.instance.cancelReminder(id);
    } else {
      await NotificationService.instance.scheduleTaskReminder(updated);
    }
    
    _refresh();
  }

  Future<void> deleteTask(String id) async {
    await _box?.delete(id);
    await NotificationService.instance.cancelReminder(id);
    _refresh();
  }

  void _refresh() {
    state = (_box?.values.toList() ?? [])
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
}

extension PlannerEntryX on PlannerEntry {
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}
