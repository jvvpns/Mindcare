import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/kelly_sound_service.dart';
import 'kelly_state_provider.dart';

/// Watches [kellyEmotionProvider] and plays a sound cue
/// only when the emotion actually changes.
///
/// Usage: Simply `ref.watch(kellySoundReactorProvider)` inside the
/// ChatbotScreen build method to activate the reactor.
final kellySoundReactorProvider = Provider<void>((ref) {
  ref.listen<String>(kellyEmotionProvider, (previous, next) {
    // Only play sound when emotion actually changes
    if (previous != null && previous != next) {
      KellySoundService.instance.playEmotionSound(next);
    }
  });
});
