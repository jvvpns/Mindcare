import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../../core/providers/health_provider.dart';
import '../../planner/providers/planner_provider.dart';
import '../../clinical_duty/providers/shift_provider.dart';
import '../../core/providers/burnout_provider.dart';
import '../../core/models/burnout_risk.dart';

/// A provider that handles the complex logic of generating Kelly's insights.
/// By moving this out of the build method, we prevent redundant calculations
/// on every frame/re-render.
final kellyInsightProvider = Provider<String>((ref) {
  final todayMood = ref.watch(todayMoodProvider);
  final sleepHours = ref.watch(sleepDurationProvider);
  final plannerEntries = ref.watch(plannerProvider);
  final shiftTasks = ref.watch(shiftProvider);
  final burnoutResult = ref.watch(burnoutRiskProvider).value;
  
  final burnoutLevel = burnoutResult?['level'] as BurnoutLevel?;
  final todayTasks = plannerEntries.where((e) => e.isDueToday && !e.isCompleted).toList();

  if (burnoutLevel == BurnoutLevel.high) {
    return "I've noticed your current load might lead to burnout. Let's take a 5-minute breathing break together?";
  }
  
  if (todayTasks.isNotEmpty) {
    final task = todayTasks.first;
    return "I see you have '${task.title}' due today. You've got this, Future Nurse!";
  }
  
  final pendingDuties = shiftTasks.where((t) => !t.isDone).toList();
  if (pendingDuties.isNotEmpty) {
    return "You have ${pendingDuties.length} pending tasks in your Shift Buddy. Don't forget to take a breather!";
  }
  
  if (sleepHours > 0 && sleepHours < 6) {
    return "I see you only had ${sleepHours.toStringAsFixed(1)} hours of sleep. Please take it easy today.";
  }
  
  if (todayMood == null) {
    return "Ready to start your shift? Don't forget to check in with how you're feeling!";
  }
  
  final mood = todayMood.moodLabel.toLowerCase();
  switch (mood) {
    case 'calm': return "You're feeling calm today. It's a great time to focus on your studies.";
    case 'happy': return "I love seeing you happy! Keep that positive energy going.";
    case 'energetic': return "You've got a lot of energy today! Maybe tackle those complex clinical charts?";
    case 'anxious': return "Feeling a bit anxious? Remember to take slow breaths. You've got this.";
    case 'sad': return "It's okay to feel sad. Take things one step at a time today.";
    case 'depressed': return "You seem really down. Please be gentle with yourself today.";
    default: return "Laban lang, Future Nurse! Every step today is a step towards your dream.";
  }
});
