import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift_task.dart';
import '../../core/services/hive_service.dart';

final shiftProvider = StateNotifierProvider<ShiftNotifier, List<ShiftTask>>((ref) {
  return ShiftNotifier();
});

class ShiftNotifier extends StateNotifier<List<ShiftTask>> {
  ShiftNotifier() : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final box = HiveService.shiftBox;
    final tasks = box.values.toList();
    
    if (tasks.isEmpty) {
      // Default tasks if none exist
      final defaultTasks = [
        ShiftTask(title: 'Receive Endorsement', category: 'Handover'),
        ShiftTask(title: 'Check Patient Vitals', category: 'Routine'),
        ShiftTask(title: 'Medication Rounds (8 AM)', category: 'Meds'),
        ShiftTask(title: 'IVF Monitoring & Regulation', category: 'Monitoring'),
        ShiftTask(title: 'Update Patient Charts', category: 'Documentation'),
        ShiftTask(title: 'Prepare for Endorsement', category: 'Handover'),
      ];
      
      for (var task in defaultTasks) {
        box.put(task.id, task);
      }
      state = defaultTasks;
    } else {
      state = tasks;
    }
  }

  Future<void> addTask(String title, String category) async {
    final task = ShiftTask(title: title, category: category);
    await HiveService.shiftBox.put(task.id, task);
    state = [...state, task];
  }

  Future<void> toggleDone(String id) async {
    final box = HiveService.shiftBox;
    final task = box.get(id);
    if (task != null) {
      task.isDone = !task.isDone;
      await task.save();
      state = [
        for (final t in state)
          if (t.id == id) t.copyWith(isDone: task.isDone) else t
      ];
    }
  }

  Future<void> deleteTask(String id) async {
    await HiveService.shiftBox.delete(id);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> resetProgress() async {
    final box = HiveService.shiftBox;
    for (var task in box.values) {
      task.isDone = false;
      await task.save();
    }
    state = [
      for (final t in state) t.copyWith(isDone: false)
    ];
  }
}
