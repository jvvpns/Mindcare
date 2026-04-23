import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/responsive_wrapper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../providers/breathing_provider.dart';
import '../providers/breathing_audio_provider.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../widgets/breathing_circle.dart';

class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(breathingProvider);
    final notifier = ref.read(breathingProvider.notifier);
    final audioState = ref.watch(breathingAudioProvider);
    final audioNotifier = ref.read(breathingAudioProvider.notifier);

    // ── Audio Control ─────────────────────────────────────────────────────
    // React to breathing state changes to start/stop/fade music
    ref.listen<BreathingState>(breathingProvider, (previous, next) {
      final audio = ref.read(breathingAudioProvider.notifier);

      // Session complete → fade out and stop
      if (next.isComplete && !(previous?.isComplete ?? false)) {
        audio.stop();
        return;
      }

      // isRunning changed
      if (previous?.isRunning != next.isRunning) {
        if (next.isRunning) {
          audio.play();
        } else {
          // Distinguish pause vs full reset
          if (next.sessionSeconds == 0) {
            audio.stop();
          } else {
            audio.pause();
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _AnimatedBackground(phase: state.phase),
          SafeArea(
            child: ResponsiveWrapper(
              child: Column(
                children: [
                  _TopBar(
                    state: state,
                    isMuted: audioState.isMuted,
                    onToggleMute: audioNotifier.toggleMute,
                    onBack: () {
                      // Stop music cleanly when leaving the screen
                      audioNotifier.stop();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.dashboard);
                      }
                    },
                  ),
                  const Spacer(flex: 1),
                  _PhaseLabel(state: state),
                  const SizedBox(height: 36),
                  BreathingCircle(
                    phase: state.phase,
                    phaseProgress: state.phaseProgress,
                    sweepProgress: state.phaseProgress,
                    countdownSecond:
                        state.phaseSecond == 0 ? 1 : state.phaseSecond,
                    isRunning: state.isRunning,
                  ),
                  const SizedBox(height: 44),
                  _CycleChips(completedCycles: state.completedCycles),
                  const Spacer(flex: 1),
                  _Controls(
                    state: state,
                    onStart: notifier.start,
                    onPause: notifier.pause,
                    onReset: notifier.reset,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (state.isComplete) _CompletionOverlay(onReset: notifier.reset),
        ],
      ),
    );
  }
}


// ── Animated Gradient Background ──────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final BreathingPhase phase;
  const _AnimatedBackground({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (c1, c2, c3) = _backgroundColors(phase);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2, c3],
        ),
      ),
    );
  }

  (Color, Color, Color) _backgroundColors(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return (
          const Color(0xFF1C2E4A),
          const Color(0xFF1A3B5C),
          const Color(0xFF0F2040),
        );
      case BreathingPhase.hold:
        return (
          const Color(0xFF261A40),
          const Color(0xFF2E1B55),
          const Color(0xFF1A1230),
        );
      case BreathingPhase.exhale:
        return (
          const Color(0xFF0D2E28),
          const Color(0xFF1A3B30),
          const Color(0xFF0A221C),
        );
      case BreathingPhase.idle:
        return (
          const Color(0xFF1A1E2E),
          const Color(0xFF1E2438),
          const Color(0xFF141824),
        );
    }
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final BreathingState state;
  final VoidCallback onBack;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const _TopBar({
    required this.state,
    required this.onBack,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _GlassButton(icon: PhosphorIconsRegular.caretLeft, onTap: onBack),
          const SizedBox(width: 10),
          // ── Mute Toggle ─────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
            child: _GlassButton(
              key: ValueKey(isMuted),
              icon: isMuted
                  ? PhosphorIconsRegular.speakerSlash
                  : PhosphorIconsRegular.speakerHigh,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggleMute();
              },
            ),
          ),
          const Spacer(),
          // ── Session Timer ─────────────────────────────────────────────
          AnimatedOpacity(
            opacity:
                state.isRunning || state.sessionSeconds > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: HilwayGlass(
              borderRadius: BorderRadius.circular(20),
              sigmaX: 12,
              sigmaY: 12,
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(PhosphorIconsRegular.timer,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 14),
                      const SizedBox(width: 6),
                      Text(
                        state.remainingLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }
}

// ── Phase Label Block ─────────────────────────────────────────────────────

class _PhaseLabel extends StatelessWidget {
  final BreathingState state;
  const _PhaseLabel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: Text(
            state.phase.label,
            key: ValueKey(state.phase),
            style: AppTextStyles.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Text(
            state.phase.sublabel,
            key: ValueKey('sub_${state.phase}'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cycle Chips ───────────────────────────────────────────────────────────

class _CycleChips extends StatelessWidget {
  final int completedCycles;
  const _CycleChips({required this.completedCycles});

  @override
  Widget build(BuildContext context) {
    const maxDots = 6;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxDots, (i) {
        final filled = i < completedCycles;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          width: filled ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: filled
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final BreathingState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _Controls({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedOpacity(
          opacity:
              state.sessionSeconds > 0 && !state.isRunning ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: _GlassButton(
            icon: PhosphorIconsRegular.arrowsClockwise,
            onTap:
                state.sessionSeconds > 0 && !state.isRunning ? onReset : () {},
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {
            if (state.isRunning) {
              HapticFeedback.lightImpact();
              onPause();
            } else {
              HapticFeedback.mediumImpact();
              onStart();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(
                colors: state.isRunning
                    ? [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.10),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.80),
                      ],
              ),
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: state.isRunning ? 0.3 : 0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                      alpha: state.isRunning ? 0.05 : 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  state.isRunning
                      ? PhosphorIconsRegular.pause
                      : PhosphorIconsRegular.play,
                  color: state.isRunning
                      ? Colors.white
                      : const Color(0xFF1A1E2E),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  state.isRunning
                      ? 'Pause'
                      : state.sessionSeconds > 0
                          ? 'Resume'
                          : 'Begin',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: state.isRunning
                        ? Colors.white
                        : const Color(0xFF1A1E2E),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        const SizedBox(width: 44), // Mirror spacer for balance
      ],
    );
  }
}

// ── Glass Button ─────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HilwayGlass(
        borderRadius: BorderRadius.circular(14),
        sigmaX: 12,
        sigmaY: 12,
        child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: PhosphorIcon(icon,
                color: Colors.white.withValues(alpha: 0.8), size: 20),
          ),
      ),
    );
  }
}

// ── Completion Overlay ────────────────────────────────────────────────────

class _CompletionOverlay extends StatelessWidget {
  final VoidCallback onReset;
  const _CompletionOverlay({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: HilwayGlass(
        sigmaX: 20,
        sigmaY: 20,
        child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: PhosphorIcon(
                        PhosphorIconsRegular.leaf,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Well done 🌿',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You completed a full breathing session.\nTake a moment to feel the calm.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.dashboard);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Done',
                              style: AppTextStyles.buttonLarge
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: onReset,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              'Again',
                              style: AppTextStyles.buttonLarge.copyWith(
                                  color: const Color(0xFF1A1E2E)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }
}