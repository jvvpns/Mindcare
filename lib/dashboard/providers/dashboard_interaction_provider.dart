import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/kelly_sound_service.dart';

/// Manages the temporary "Nudge" messages when Kelly is poked on the dashboard.
final kellyPokedMessageProvider = StateNotifierProvider<KellyPokedMessageNotifier, String?>((ref) {
  return KellyPokedMessageNotifier();
});

class KellyPokedMessageNotifier extends StateNotifier<String?> {
  KellyPokedMessageNotifier() : super(null);
  
  Timer? _timer;

  /// Trigger a random nudge message.
  void poke() {
    _timer?.cancel();
    
    // Play a "happy" digital tone
    KellySoundService.instance.playEmotionSound(AppConstants.kellyHappy);
    
    // Pick a random nudge
    final random = Random();
    final nudge = AppConstants.kellyNudges[random.nextInt(AppConstants.kellyNudges.length)];
    
    state = nudge;

    // Clear after 4 seconds
    _timer = Timer(const Duration(seconds: 4), () {
      state = null;
    });
  }
}
