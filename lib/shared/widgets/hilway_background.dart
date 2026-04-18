import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A reactive, animated background for every HILWAY screen.
///
/// **Architecture:**
/// - 3 large "drift orbs" auto-animate on slow sine curves — they breathe,
///   never stop, and never repeat the same pattern thanks to different periods.
/// - 1 "touch orb" that smoothly follows the user's finger.
/// - All orbs are painted with RadialGradients at 5-12% opacity, no
///   BackdropFilter, so the GPU cost is minimal on iOS.
/// - The child is wrapped in a RepaintBoundary so scroll/interactive widgets
///   never get caught by the background repaint cycle.
class HilwayBackground extends StatefulWidget {
  final Widget child;

  const HilwayBackground({super.key, required this.child});

  @override
  State<HilwayBackground> createState() => _HilwayBackgroundState();
}

class _HilwayBackgroundState extends State<HilwayBackground>
    with TickerProviderStateMixin {
  // ── Drift controllers (slow sine-wave float) ────────────────────────────
  late final AnimationController _drift1;
  late final AnimationController _drift2;
  late final AnimationController _drift3;

  // ── Touch orb state ──────────────────────────────────────────────────────
  Offset? _touchPos;
  Offset _orbPos = const Offset(0, 0);

  // ── Orb animations output values ────────────────────────────────────────
  late final Animation<double> _t1;
  late final Animation<double> _t2;
  late final Animation<double> _t3;

  @override
  void initState() {
    super.initState();

    // Different durations so the three orbs never synchronise
    _drift1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _drift2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 17),
    )..repeat(reverse: true);

    _drift3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 23),
    )..repeat(reverse: true);

    // Map each controller 0→1 with ease-in-out for that floating feeling
    _t1 = CurvedAnimation(parent: _drift1, curve: Curves.easeInOut);
    _t2 = CurvedAnimation(parent: _drift2, curve: Curves.easeInOut);
    _t3 = CurvedAnimation(parent: _drift3, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _drift1.dispose();
    _drift2.dispose();
    _drift3.dispose();
    super.dispose();
  }

  // Smooth lerp of the touch-orb toward the finger
  void _onPointerMove(PointerEvent event) {
    setState(() {
      _touchPos = event.localPosition;
      // Lazy-follow: move 18% toward the target each frame
      _orbPos = Offset(
        _lerp(_orbPos.dx, event.localPosition.dx, 0.18),
        _lerp(_orbPos.dy, event.localPosition.dy, 0.18),
      );
    });
  }

  void _onPointerUp(PointerEvent event) {
    setState(() => _touchPos = null);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_t1, _t2, _t3]),
        builder: (context, _) {
          // ── Orb 1: primary/blue — top area, drifts left-right ──────────
          final orb1 = Offset(
            size.width * (_lerpV(0.05, 0.35, _t1.value)),
            size.height * (_lerpV(0.00, 0.18, _t2.value)),
          );

          // ── Orb 2: accent/lavender — bottom area, drifts diagonally ────
          final orb2 = Offset(
            size.width * (_lerpV(0.55, 0.95, _t2.value)),
            size.height * (_lerpV(0.65, 0.95, _t3.value)),
          );

          // ── Orb 3: secondary/sage — mid-right, slow vertical drift ─────
          final orb3 = Offset(
            size.width * (_lerpV(0.60, 0.90, _t3.value)),
            size.height * (_lerpV(0.25, 0.50, _t1.value)),
          );

          return CustomPaint(
            painter: _BackgroundPainter(
              orb1: orb1,
              orb2: orb2,
              orb3: orb3,
              touchOrb: _touchPos != null ? _orbPos : null,
            ),
            child: RepaintBoundary(child: widget.child),
          );
        },
      ),
    );
  }

  static double _lerpV(double a, double b, double t) => a + (b - a) * t;
}

class _BackgroundPainter extends CustomPainter {
  final Offset orb1;
  final Offset orb2;
  final Offset orb3;
  final Offset? touchOrb;

  const _BackgroundPainter({
    required this.orb1,
    required this.orb2,
    required this.orb3,
    this.touchOrb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Base background ──────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF9F8F6), // Top left stays soft
          Color(0xFFE8E6E0), // Bottom right deepened for contrast
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Draw an orb as a soft radial gradient circle ─────────────────────
    void drawOrb(Offset center, Color color, double radius, double opacity) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // Orb 1 — Soft Blue (primary)
    drawOrb(orb1, AppColors.primary, size.width * 0.70, 0.15);

    // Orb 2 — Warm Lavender (accent)
    drawOrb(orb2, AppColors.accent, size.width * 0.65, 0.12);

    // Orb 3 — Sage Green (secondary)
    drawOrb(orb3, AppColors.secondary, size.width * 0.50, 0.10);

    // Touch orb — slightly brighter accent that trails the finger
    if (touchOrb != null) {
      drawOrb(touchOrb!, AppColors.accent, size.width * 0.40, 0.22);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.orb1 != orb1 ||
      old.orb2 != orb2 ||
      old.orb3 != orb3 ||
      old.touchOrb != touchOrb;
}
