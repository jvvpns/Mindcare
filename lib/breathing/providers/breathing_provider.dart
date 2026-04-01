import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Breathing Phase ────────────────────────────────────────────────────────

enum BreathingPhase { idle, inhale, hold, exhale }

extension BreathingPhaseExtension on BreathingPhase {
  String get label {
    switch (this) {
      case BreathingPhase.inhale:
        return 'Inhale';
      case BreathingPhase.hold:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Exhale';
      case BreathingPhase.idle:
        return 'Ready';
    }
  }

  String get sublabel {
    switch (this) {
      case BreathingPhase.inhale:
        return 'Breathe in slowly through your nose';
      case BreathingPhase.hold:
        return 'Hold gently — you\'re doing great';
      case BreathingPhase.exhale:
        return 'Let it all go, breathe out softly';
      case BreathingPhase.idle:
        return 'Find a comfortable position and begin';
    }
  }

  int get durationSeconds => 4;
}

// ── Breathing State ────────────────────────────────────────────────────────

class BreathingState {
  final BreathingPhase phase;
  final int phaseSecond;       // 1 to 4 within the current phase
  final int sessionSeconds;    // Total elapsed session seconds
  final int targetSeconds;     // Session target (default 120s = 2 min)
  final bool isRunning;
  final bool isComplete;
  final int completedCycles;

  const BreathingState({
    this.phase = BreathingPhase.idle,
    this.phaseSecond = 0,
    this.sessionSeconds = 0,
    this.targetSeconds = 120,
    this.isRunning = false,
    this.isComplete = false,
    this.completedCycles = 0,
  });

  /// Animation progress within the current phase: 0.0 → 1.0
  double get phaseProgress =>
      phase == BreathingPhase.idle ? 0.0 : phaseSecond / phase.durationSeconds;

  /// Session progress: 0.0 → 1.0
  double get sessionProgress =>
      (sessionSeconds / targetSeconds).clamp(0.0, 1.0);

  /// Remaining session time as "MM:SS"
  String get remainingLabel {
    final remaining = (targetSeconds - sessionSeconds).clamp(0, targetSeconds);
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  BreathingState copyWith({
    BreathingPhase? phase,
    int? phaseSecond,
    int? sessionSeconds,
    int? targetSeconds,
    bool? isRunning,
    bool? isComplete,
    int? completedCycles,
  }) {
    return BreathingState(
      phase: phase ?? this.phase,
      phaseSecond: phaseSecond ?? this.phaseSecond,
      sessionSeconds: sessionSeconds ?? this.sessionSeconds,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      isRunning: isRunning ?? this.isRunning,
      isComplete: isComplete ?? this.isComplete,
      completedCycles: completedCycles ?? this.completedCycles,
    );
  }
}

// ── Breathing Notifier ─────────────────────────────────────────────────────

class BreathingNotifier extends StateNotifier<BreathingState> {
  BreathingNotifier() : super(const BreathingState());

  Timer? _timer;

  // Phase sequence: inhale → hold → exhale → inhale → …
  static const _sequence = [
    BreathingPhase.inhale,
    BreathingPhase.hold,
    BreathingPhase.exhale,
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  void start() {
    if (state.isRunning) return;
    _startPhase(BreathingPhase.inhale, keepSession: state.sessionSeconds > 0);
    state = state.copyWith(isRunning: true, isComplete: false);
    _scheduleTick();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = const BreathingState();
  }

  void setTarget(int seconds) {
    state = state.copyWith(targetSeconds: seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _startPhase(BreathingPhase phase, {bool keepSession = false}) {
    state = state.copyWith(
      phase: phase,
      phaseSecond: 1,
      sessionSeconds: keepSession ? state.sessionSeconds : 0,
    );
    _triggerHaptic(phase);
  }

  void _scheduleTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!state.isRunning) return;

    final newSession = state.sessionSeconds + 1;
    final newPhaseSecond = state.phaseSecond + 1;

    // Session complete?
    if (newSession >= state.targetSeconds) {
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 300), HapticFeedback.heavyImpact);
      Future.delayed(const Duration(milliseconds: 600), HapticFeedback.heavyImpact);
      state = state.copyWith(
        sessionSeconds: newSession,
        isRunning: false,
        isComplete: true,
        phase: BreathingPhase.idle,
      );
      return;
    }

    // Tick haptic (soft click each second)
    HapticFeedback.selectionClick();

    // Phase complete?
    if (newPhaseSecond > state.phase.durationSeconds) {
      final nextPhase = _nextPhase(state.phase);
      final newCycles = nextPhase == BreathingPhase.inhale
          ? state.completedCycles + 1
          : state.completedCycles;
      state = state.copyWith(
        phase: nextPhase,
        phaseSecond: 1,
        sessionSeconds: newSession,
        completedCycles: newCycles,
      );
      _triggerHaptic(nextPhase);
    } else {
      state = state.copyWith(
        phaseSecond: newPhaseSecond,
        sessionSeconds: newSession,
      );
    }
  }

  BreathingPhase _nextPhase(BreathingPhase current) {
    final idx = _sequence.indexOf(current);
    return _sequence[(idx + 1) % _sequence.length];
  }

  void _triggerHaptic(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        HapticFeedback.mediumImpact();
        break;
      case BreathingPhase.hold:
        HapticFeedback.lightImpact();
        break;
      case BreathingPhase.exhale:
        HapticFeedback.mediumImpact();
        break;
      case BreathingPhase.idle:
        break;
    }
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final breathingProvider =
    StateNotifierProvider.autoDispose<BreathingNotifier, BreathingState>(
  (ref) => BreathingNotifier(),
);
