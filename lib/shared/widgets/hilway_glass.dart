import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/utils/device_utils.dart';

/// A performance-aware frosted glass layer.
/// 
/// On desktop and native mobile, it renders a high-fidelity Gaussian blur
/// using [BackdropFilter].
/// 
/// On mobile web browsers, where `BackdropFilter` causes severe frame drops
/// during scrolling, it gracefully degrades to a simple pass-through layer,
/// allowing the semi-transparent color of the child's container to provide
/// a "flat glass" look without the expensive blur calculations.
class HilwayGlass extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final BorderRadiusGeometry? borderRadius;

  const HilwayGlass({
    super.key,
    required this.child,
    this.sigmaX = 12.0,
    this.sigmaY = 12.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (DeviceUtils.isMobileWeb) {
      // Mobile Web Fallback: No blur. The child's background color 
      // (which should be semi-transparent) will provide the frosted aesthetic.
      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: child,
        );
      }
      return child;
    }

    // High-Fidelity Blur for Desktop/Native
    Widget blurredChild = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: blurredChild,
      );
    }

    return blurredChild;
  }
}
