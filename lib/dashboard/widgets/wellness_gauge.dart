import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/burnout_service.dart';

class WellnessGauge extends StatefulWidget {
  final double score; // 0.0 to 1.0
  final BurnoutLevel level;
  final String label;

  const WellnessGauge({
    super.key,
    required this.score,
    required this.level,
    required this.label,
  });

  @override
  State<WellnessGauge> createState() => _WellnessGaugeState();
}

class _WellnessGaugeState extends State<WellnessGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(WellnessGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: oldWidget.score,
        end: widget.score,
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 90,
          width: 160,
          child: AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _GaugePainter(
                  score: _scoreAnimation.value,
                  level: widget.level,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'AI Resilience Scan',
          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final BurnoutLevel level;

  _GaugePainter({required this.score, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // ── Background Arc ───────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = AppColors.surfaceSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // ── Active Gradient Arc ──────────────────────────────────────────────────
    final colors = [
      AppColors.crisis,          // Left (Low resilience / Red)
      AppColors.moodStressed,    // Mid
      AppColors.primary,         // Right (High resilience / Teal)
    ];

    final gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi * 2,
      colors: colors,
      stops: const [0.1, 0.5, 0.9],
    );

    // We use a Rect for the gradient that matches the arc's circle
    final rect = Rect.fromCircle(center: center, radius: radius);

    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw the active portion based on score
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * score,
      false,
      activePaint,
    );

    // ── Needle Indicator ─────────────────────────────────────────────────────
    final needleAngle = math.pi + (math.pi * score);
    final needleRadius = radius + 4;
    final needlePos = Offset(
      center.dx + needleRadius * math.cos(needleAngle),
      center.dy + needleRadius * math.sin(needleAngle),
    );

    // Needle shadow/glow
    final glowPaint = Paint()
      ..color = _getLevelColor(level).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(needlePos, 8, glowPaint);

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needlePos, 5, needlePaint);

    // Inner circle (cap)
    canvas.drawCircle(center, 4, activePaint..style = PaintingStyle.fill);
  }

  Color _getLevelColor(BurnoutLevel level) {
    switch (level) {
      case BurnoutLevel.low:
        return AppColors.primary;
      case BurnoutLevel.medium:
        return AppColors.moodStressed;
      case BurnoutLevel.high:
        return AppColors.crisis;
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score;
}
