import 'package:flutter/foundation.dart';

/// Utility class for device and platform specific checks.
class DeviceUtils {
  DeviceUtils._();

  /// Returns true if the application is running in a mobile web browser.
  /// Used to gracefully degrade heavy graphical effects (like BackdropFilter 
  /// and heavy BoxShadows) that cause frame drops on mobile WebGL/CanvasKit.
  static bool get isMobileWeb {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS || 
           defaultTargetPlatform == TargetPlatform.android;
  }
}
