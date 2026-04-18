import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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

  const HilwayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.onTap,
    this.isGlass = false,
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
      width: double.infinity,
      padding: widget.padding,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: widget.child,
    );
  }

  // ── Glass variant ───────────────────────────────────────────────────────
  Widget _buildGlass() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: (widget.color ?? Colors.white).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
