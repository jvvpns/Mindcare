import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/device_utils.dart';
import 'hilway_glass.dart';

/// A premium card widget with optional glassmorphism and micro-animation.
///
/// Set [isGlass] to `true` to render a frosted-glass card with a
/// `BackdropFilter` blur — ideal for layers that sit above gradient
/// or image backgrounds. Regular (non-glass) cards use a flat white
/// surface with a subtle shadow.
class HilwayCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  /// Enables the Glassmorphism effect (BackdropFilter + frosted border).
  final bool isGlass;

  /// Optional glow/shadow color to complement the design.
  final Color? glowColor;

  /// The width of the card. Defaults to double.infinity.
  final double? width;

  const HilwayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.onTap,
    this.isGlass = false,
    this.glowColor,
    this.width = double.infinity,
  });

  @override
  State<HilwayCard> createState() => _HilwayCardState();
}

class _HilwayCardState extends State<HilwayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Press Handlers ──────────────────────────────────────────────────────
  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _animController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _animController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _animController.reverse();

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final child = widget.isGlass ? _buildGlass() : _buildSolid();

    if (widget.onTap == null) return child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: child,
      ),
    );
  }

  // ── Solid variant ───────────────────────────────────────────────────────
  Widget _buildSolid() {
    return Container(
      width: widget.width,
      padding: widget.padding,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (widget.glowColor ?? Colors.black).withValues(alpha: widget.glowColor != null ? 0.12 : 0.04),
            blurRadius: DeviceUtils.isMobileWeb ? (widget.glowColor != null ? 12 : 8) : (widget.glowColor != null ? 24 : 20),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: widget.child,
    );
  }

  Widget _buildGlass() {
    return HilwayGlass(
      borderRadius: BorderRadius.circular(24),
      sigmaX: 12,
      sigmaY: 12,
      child: Container(
          width: widget.width,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (widget.color ?? Colors.white).withValues(alpha: 0.75),
                (widget.color ?? Colors.white).withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.glowColor ?? Colors.black).withValues(alpha: widget.glowColor != null ? 0.18 : 0.06),
                blurRadius: DeviceUtils.isMobileWeb ? (widget.glowColor != null ? 16 : 8) : (widget.glowColor != null ? 36 : 24),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: widget.child,
        ),
    );
  }
}
