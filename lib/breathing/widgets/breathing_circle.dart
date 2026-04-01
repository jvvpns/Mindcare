import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../providers/breathing_provider.dart';

// ── Progress Ring Painter ──────────────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final BreathingPhase phase;
  final double sweepProgress;

  _ProgressRingPainter({
    required this.progress,
    required this.phase,
    required this.sweepProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guard: skip all drawing if there's nothing to paint yet (avoids dart:ui assertion)
    if (sweepProgress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // ── Track ring
    final trackPaint = Paint()
      ..color = _phaseColor(phase).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // ── Active arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * sweepProgress,
        colors: [
          _phaseColor(phase).withValues(alpha: 0.5),
          _phaseColor(phase),
        ],
        tileMode: TileMode.clamp,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * sweepProgress,
      false,
      arcPaint,
    );

    // ── Glowing tip dot
    if (sweepProgress > 0.01) {
      final angle = -math.pi / 2 + 2 * math.pi * sweepProgress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);
      final dotPaint = Paint()
        ..color = _phaseColor(phase)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
      canvas.drawCircle(
        Offset(dotX, dotY),
        3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.sweepProgress != sweepProgress || old.phase != phase;
}

Color _phaseColor(BreathingPhase phase) {
  switch (phase) {
    case BreathingPhase.inhale:
      return AppColors.primary;
    case BreathingPhase.hold:
      return AppColors.accent;
    case BreathingPhase.exhale:
      return AppColors.secondary;
    case BreathingPhase.idle:
      return AppColors.textHint;
  }
}

// ── Floating Orb ──────────────────────────────────────────────────────────

class _FloatingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double offsetX;
  final double offsetY;
  final double opacity;

  const _FloatingOrb({
    required this.size,
    required this.color,
    required this.offsetX,
    required this.offsetY,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Breathing Circle Widget ────────────────────────────────────────────────

class BreathingCircle extends StatefulWidget {
  final BreathingPhase phase;
  final double phaseProgress;
  final double sweepProgress;
  final int countdownSecond;
  final bool isRunning;

  const BreathingCircle({
    super.key,
    required this.phase,
    required this.phaseProgress,
    required this.sweepProgress,
    required this.countdownSecond,
    required this.isRunning,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _orbController;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _orbAnim = CurvedAnimation(
      parent: _orbController,
      curve: Curves.easeInOut,
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(BreathingCircle old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase || old.isRunning != widget.isRunning) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (!widget.isRunning) {
      _pulseController.stop();
      _orbController.stop();
      _pulseController.value = 0.0;
      _orbController.value = 0.0;
      return;
    }
    _pulseController.reset();
    _orbController.reset();

    switch (widget.phase) {
      case BreathingPhase.inhale:
        _pulseController.animateTo(1.0,
            duration: const Duration(milliseconds: 4000),
            curve: Curves.easeInOut);
        _orbController.animateTo(1.0,
            duration: const Duration(milliseconds: 4000),
            curve: Curves.easeOut);
      case BreathingPhase.hold:
        _pulseController.value = 1.0;
        _orbController.value = 1.0;
        _pulseController.repeat(
          min: 0.92,
          max: 1.0,
          reverse: true,
          period: const Duration(milliseconds: 1200),
        );
      case BreathingPhase.exhale:
        _pulseController.animateTo(0.0,
            duration: const Duration(milliseconds: 4000),
            curve: Curves.easeInOut);
        _orbController.animateTo(0.0,
            duration: const Duration(milliseconds: 4000),
            curve: Curves.easeIn);
      case BreathingPhase.idle:
        _pulseController.value = 0.0;
        _orbController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor(widget.phase);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _orbAnim]),
      builder: (context, _) {
        final scale = 0.75 + (_pulseAnim.value * 0.25);
        final orbDist = _orbAnim.value * 52;

        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Outer diffuse glow
              Container(
                width: 280 * scale,
                height: 280 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.08 * scale),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),

              // ── Floating ambient orbs
              _FloatingOrb(
                size: 80,
                color: color,
                offsetX: -orbDist * 0.8,
                offsetY: -orbDist * 0.9,
                opacity: 0.18 * _orbAnim.value,
              ),
              _FloatingOrb(
                size: 60,
                color: AppColors.accent,
                offsetX: orbDist * 0.9,
                offsetY: -orbDist * 0.5,
                opacity: 0.14 * _orbAnim.value,
              ),
              _FloatingOrb(
                size: 50,
                color: AppColors.secondary,
                offsetX: -orbDist * 0.3,
                offsetY: orbDist * 1.0,
                opacity: 0.12 * _orbAnim.value,
              ),
              _FloatingOrb(
                size: 45,
                color: color,
                offsetX: orbDist * 0.7,
                offsetY: orbDist * 0.6,
                opacity: 0.10 * _orbAnim.value,
              ),

              // ── Progress ring
              SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: widget.phaseProgress,
                    phase: widget.phase,
                    sweepProgress: widget.sweepProgress,
                  ),
                ),
              ),

              // ── Main glass sphere
              _GlassSphere(scale: scale, color: color),

              // ── Countdown number
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: widget.isRunning
                    ? Text(
                        '${widget.countdownSecond}',
                        key: ValueKey(widget.countdownSecond),
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 52,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.0,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Glass Sphere ──────────────────────────────────────────────────────────

class _GlassSphere extends StatelessWidget {
  final double scale;
  final Color color;

  const _GlassSphere({required this.scale, required this.color});

  @override
  Widget build(BuildContext context) {
    final size = 190.0 * scale;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 1.0,
              colors: [
                Colors.white.withValues(alpha: 0.28),
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.30 * scale),
                blurRadius: 40,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.15 * scale),
                blurRadius: 80,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: size * 0.12,
                left: size * 0.18,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
