import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/services/hive_service.dart';
import '../providers/auth_provider.dart';
import '../../chatbot/widgets/kelly_orb_mascot.dart';

/// A premium, 10-second cinematic intro animation inspired by Apple's
/// macOS Monterey "Hello" startup sequence. The scene:
///
///   0.0s → 3.0s : Kelly orb fades in from total darkness (ease-in-out cubic)
///   1.6s → 7.0s : Orb pulsates, cycles through HILWAY brand colors,
///                  radiating soft halos onto the background
///   2.4s → 5.6s : "Hilway" heading fades in
///   3.6s → 6.4s : Subtext fades in beneath
///   7.0s → 10.0s : Final hold (3.0s), then gentle dissolve to next screen
///
class CinematicIntroScreen extends ConsumerStatefulWidget {
  const CinematicIntroScreen({super.key});

  @override
  ConsumerState<CinematicIntroScreen> createState() =>
      _CinematicIntroScreenState();
}

class _CinematicIntroScreenState extends ConsumerState<CinematicIntroScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ─────────────────────────────────────────────────
  late final AnimationController _masterController; // 10s total timeline
  late final AnimationController _pulseController; // Continuous orb pulse
  late final AnimationController _colorController; // Brand color cycling

  // ── Derived Animations ────────────────────────────────────────────────────
  late final Animation<double> _orbFadeIn; // 0.0s → 3.0s
  late final Animation<double> _orbScale; // Subtle breathe
  late final Animation<double> _titleFadeIn; // 2.4s → 5.6s
  late final Animation<double> _subtextFadeIn; // 3.6s → 6.4s
  late final Animation<double> _sceneDissolve; // 9.0s → 10.0s (fade out)
  late final Animation<double> _bgGlowIntensity; // 1.6s → 6.0s

  // ── Kelly Emotion Sequence ────────────────────────────────────────────────
  /// Kelly orb cycles through these emotions during intro:
  static const List<String> _emotions = [
    AppConstants.kellyDefault,
    AppConstants.kellyHappy,
    AppConstants.kellyCalm,
    AppConstants.kellyExcited,
    AppConstants.kellySurprised,
    AppConstants.kellyHappy,
  ];

  // ── Brand Color Sequence (Sync with KellyOrbMascot) ───────────────────────
  static const List<Color> _brandColors = [
    Color(0xFFF9F8F6), // Default — Off-white
    Color(0xFF4FC3F7), // Happy — Sky Blue
    Color(0xFF4DB6AC), // Calm — Deep Teal/Mint
    Color(0xFFFFD54F), // Excited — Gold
    Color(0xFFF06292), // Surprised — Pink
    Color(0xFF4FC3F7), // Happy
  ];

  int _currentColorIndex = 0;
  int _nextColorIndex = 1;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ── Master timeline: 10 seconds total ──────────────────────────────────
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );

    // ── Pulse: Deep meditative 'breather' pulse (10s cycle) ────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat(reverse: true);

    // ── Color cycling: 2000ms for ultra-smooth ethereal transitions ────────
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener(_onColorCycleComplete);

    // ── Orb fade-in: 0% → 30% of timeline (0s → 1.5s) ───────────────────
    _orbFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeInOutCubic),
      ),
    );

    // ── Orb breathing scale via pulse controller ─────────────────────────
    _orbScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // ── Background glow intensity: 16% → 60% of timeline ────────────────
    _bgGlowIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.16, 0.60, curve: Curves.easeOut),
      ),
    );

    // ── Title "Hilway" fade-in: 24% → 56% (2.4s → 5.6s) ────────────────
    _titleFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.24, 0.56, curve: Curves.easeInOutCubic),
      ),
    );

    // ── Subtext fade-in: 36% → 64% (3.6s → 6.4s) ───────────────────────
    _subtextFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.36, 0.64, curve: Curves.easeInOutCubic),
      ),
    );

    // ── Scene dissolve: 90% → 100% (9.0s → 10.0s) ───────────────────────
    _sceneDissolve = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── Start the show ──────────────────────────────────────────────────
    _masterController.forward();

    // Start color cycling after a short delay (when orb is partially visible)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _colorController.forward();
    });

    // Navigate to the correct screen after animation completes
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (_navigated) return;
    _navigated = true;

    // Determine destination based on auth state
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    final hasSeenOnboarding =
        HiveService.settingsBox.get(
              AppConstants.keyHasSeenOnboarding,
              defaultValue: false,
            )
            as bool;

    if (isAuthenticated) {
      context.go(AppRoutes.splash);
    } else if (hasSeenOnboarding) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  void _onColorCycleComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _currentColorIndex = _nextColorIndex;
      _nextColorIndex = (_nextColorIndex + 1) % _brandColors.length;

      // Stop cycling if the master animation is winding down
      if (_masterController.value < 0.85) {
        _colorController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _masterController,
          _pulseController,
          _colorController,
        ]),
        builder: (context, _) {
          // Interpolate current orb color
          final orbColor = Color.lerp(
            _brandColors[_currentColorIndex],
            _brandColors[_nextColorIndex],
            _colorController.value,
          )!;

          return GestureDetector(
            onTap: _navigateToNextScreen,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: _sceneDissolve.value,
              child: Stack(
                children: [
                  // ── Layer 1: Animated Background Gradient ─────────────────
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CinematicBgPainter(
                        orbColor: orbColor,
                        glowIntensity: _bgGlowIntensity.value,
                        orbFade: _orbFadeIn.value,
                      ),
                    ),
                  ),

                  // ── Layer 2: Centered Content ────────────────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Kelly Orb Mascot ───────────────────────────────
                        Opacity(
                          opacity: _orbFadeIn.value,
                          child: Transform.scale(
                            scale: _orbScale.value,
                            child: SizedBox(
                              width: 140,
                              height: 140,
                              child: KellyOrbMascot(
                                emotion: _emotions[_currentColorIndex],
                                size: 100,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── "Hilway" Heading ───────────────────────────────
                        Opacity(
                          opacity: _titleFadeIn.value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1.0 - _titleFadeIn.value)),
                            child: Text(
                              'Hilway',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 6,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: orbColor.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                  ),
                                  Shadow(
                                    color: orbColor.withValues(alpha: 0.2),
                                    blurRadius: 60,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Subtext ────────────────────────────────────────
                        Opacity(
                          opacity: _subtextFadeIn.value,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1.0 - _subtextFadeIn.value)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                              ),
                              child: Text(
                                'Holistic Inner Life Well-being\nand AI for You',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withValues(alpha: 0.70),
                                  letterSpacing: 1.2,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Layer 3: Skip Hint ───────────────────────────────────
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity:
                            (_masterController.value > 0.2 &&
                                _masterController.value < 0.8)
                            ? 0.4
                            : 0.0,
                        child: Text(
                          'Tap to skip',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CINEMATIC BACKGROUND PAINTER — Soft radial halo from orb color
// ═══════════════════════════════════════════════════════════════════════════════

class _CinematicBgPainter extends CustomPainter {
  final Color orbColor;
  final double glowIntensity;
  final double orbFade;

  _CinematicBgPainter({
    required this.orbColor,
    required this.glowIntensity,
    required this.orbFade,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // ── Base: Pure black ─────────────────────────────────────────────────
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // ── Halo: Large, ultra-soft radial gradient centered behind the orb ──
    final center = Offset(size.width / 2, size.height * 0.38);
    final maxRadius = size.height * 0.9;
    final effectiveOpacity = glowIntensity * orbFade;

    if (effectiveOpacity > 0.001) {
      // Primary halo
      final haloPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            orbColor.withValues(alpha: 0.18 * effectiveOpacity),
            orbColor.withValues(alpha: 0.08 * effectiveOpacity),
            orbColor.withValues(alpha: 0.02 * effectiveOpacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

      canvas.drawCircle(center, maxRadius, haloPaint);

      // Secondary halo (wider, softer)
      final halo2Paint = Paint()
        ..shader =
            RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                orbColor.withValues(alpha: 0.06 * effectiveOpacity),
                orbColor.withValues(alpha: 0.015 * effectiveOpacity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ).createShader(
              Rect.fromCircle(center: center, radius: maxRadius * 1.4),
            );

      canvas.drawCircle(center, maxRadius * 1.4, halo2Paint);

      // Subtle vertical gradient wash for depth
      final washPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            orbColor.withValues(alpha: 0.03 * effectiveOpacity),
            orbColor.withValues(alpha: 0.06 * effectiveOpacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ).createShader(Offset.zero & size);

      canvas.drawRect(Offset.zero & size, washPaint);
    }
  }

  @override
  bool shouldRepaint(_CinematicBgPainter old) =>
      old.orbColor != orbColor ||
      old.glowIntensity != glowIntensity ||
      old.orbFade != orbFade;
}
