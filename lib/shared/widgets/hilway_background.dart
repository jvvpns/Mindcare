import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A reactive, animated background for every HILWAY screen.
class HilwayBackground extends StatefulWidget {
  final Widget child;
  final String emotion;

  const HilwayBackground({
    super.key, 
    required this.child,
    this.emotion = 'default',
  });

  @override
  State<HilwayBackground> createState() => _HilwayBackgroundState();
}

class _HilwayBackgroundState extends State<HilwayBackground>
    with TickerProviderStateMixin {
  // ── Drift controllers ──────────────────────────────────────────────────
  late final AnimationController _drift1;
  late final AnimationController _drift2;
  late final AnimationController _drift3;

  // ── Color transition controller ─────────────────────────────────────────
  late final AnimationController _colorController;

  // ── Touch orb state ──────────────────────────────────────────────────────
  Offset? _touchPos;
  Offset _orbPos = const Offset(0, 0);

  // ── Orb animations ───────────────────────────────────────────────────────
  late final Animation<double> _t1;
  late final Animation<double> _t2;
  late final Animation<double> _t3;

  // ── Color animation state ───────────────────────────────────────────────
  List<Color> _currentColors = AppColors.emotionToColors['default']!;
  List<Color> _targetColors = AppColors.emotionToColors['default']!;

  // ── Parallax state ───────────────────────────────────────────────────────
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();

    _currentColors = AppColors.emotionToColors[widget.emotion] ?? AppColors.emotionToColors['default']!;
    _targetColors = _currentColors;

    _drift1 = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
    _drift2 = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat(reverse: true);
    _drift3 = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(reverse: true);

    _colorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _t1 = CurvedAnimation(parent: _drift1, curve: Curves.easeInOut);
    _t2 = CurvedAnimation(parent: _drift2, curve: Curves.easeInOut);
    _t3 = CurvedAnimation(parent: _drift3, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(HilwayBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _currentColors = _targetColors;
      _targetColors = AppColors.emotionToColors[widget.emotion] ?? AppColors.emotionToColors['default']!;
      _colorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _drift1.dispose();
    _drift2.dispose();
    _drift3.dispose();
    _colorController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event) {
    setState(() {
      _touchPos = event.localPosition;
      _orbPos = Offset(
        _lerp(_orbPos.dx, event.localPosition.dx, 0.12),
        _lerp(_orbPos.dy, event.localPosition.dy, 0.12),
      );
    });
  }

  void _onPointerUp(PointerEvent event) {
    setState(() => _touchPos = null);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _lerpV(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _scrollOffset.value = notification.metrics.pixels;
          }
          return false;
        },
        child: Stack(
          children: [
            // ── Animated & Parallax Background Layer ──
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollOffset,
                builder: (context, scrollVal, _) {
                  return RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_t1, _t2, _t3, _colorController]),
                      builder: (context, _) {
                        final color1 = Color.lerp(_currentColors[0], _targetColors[0], _colorController.value) ?? _currentColors[0];
                        final color2 = Color.lerp(_currentColors[1], _targetColors[1], _colorController.value) ?? _currentColors[1];
      
                        final size = MediaQuery.of(context).size;
                        
                        // Base positions with drift
                        final orb1 = Offset(size.width * _lerpV(0.05, 0.35, _t1.value), size.height * _lerpV(0.00, 0.18, _t2.value));
                        final orb2 = Offset(size.width * _lerpV(0.55, 0.95, _t2.value), size.height * _lerpV(0.65, 0.95, _t3.value));
                        final orb3 = Offset(size.width * _lerpV(0.60, 0.90, _t3.value), size.height * _lerpV(0.25, 0.50, _t1.value));
      
                        return CustomPaint(
                          painter: _BackgroundPainter(
                            orb1: orb1,
                            orb2: orb2,
                            orb3: orb3,
                            baseColor: color1,
                            accentColor: color2,
                            emotion: widget.emotion,
                            touchOrb: _touchPos != null ? _orbPos : null,
                            scrollOffset: scrollVal,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            
            // ── Screen Content Layer ──
            Positioned.fill(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Offset orb1;
  final Offset orb2;
  final Offset orb3;
  final Offset? touchOrb;
  final Color baseColor;
  final Color accentColor;
  final String emotion;
  final double scrollOffset;

  _BackgroundPainter({
    required this.orb1,
    required this.orb2,
    required this.orb3,
    required this.baseColor,
    required this.accentColor,
    required this.emotion,
    this.touchOrb,
    this.scrollOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    
    // ── Base gradient: Top-left to bottom-right ─────────────────────────────
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [baseColor, accentColor.withValues(alpha: 0.7), baseColor.withValues(alpha: 0.9)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    void drawOrb(Offset center, Color color, double radius, double opacity, double parallaxFactor) {
      // Apply parallax shift: deeper orbs move slower
      final parallaxCenter = Offset(
        center.dx,
        center.dy - (scrollOffset * parallaxFactor),
      );

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: parallaxCenter, radius: radius));
      canvas.drawCircle(parallaxCenter, radius, paint);
    }

    // ── Orbs with Parallax ──────────────────────────────────────────────────
    // Lower factor = background, moves less. Higher factor = foreground, moves more.
    drawOrb(orb1, accentColor, size.width * 0.75, 0.22, 0.05); // Deep background
    drawOrb(orb2, accentColor, size.width * 0.65, 0.18, 0.12); // Middle
    drawOrb(orb3, baseColor, size.width * 0.55, 0.14, 0.08);  // Slight depth

    // ── Extra: subtle top-left accent wash for depth ────────────────────────
    final accentCenter = Offset(size.width * 0.15, size.height * 0.08 - (scrollOffset * 0.03));
    drawOrb(accentCenter, accentColor, size.width * 0.5, 0.12, 0.0);

    if (touchOrb != null) {
      drawOrb(touchOrb!, AppColors.accent, size.width * 0.40, 0.25, 0.0);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.orb1 != orb1 ||
      old.orb2 != orb2 ||
      old.orb3 != orb3 ||
      old.touchOrb != touchOrb ||
      old.baseColor != baseColor ||
      old.accentColor != accentColor ||
      old.emotion != emotion ||
      old.scrollOffset != scrollOffset;
}
