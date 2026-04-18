import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Manages ambient sound cues for Kelly's emotional state.
///
/// Plays short synthetic/digital tones when Kelly's emotion changes.
/// Sounds are kept subtle (30% volume) and only fire on actual transitions,
/// not on every message.
class KellySoundService {
  KellySoundService._();
  static final KellySoundService instance = KellySoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  /// Emotion → asset path mapping
  static const _emotionSounds = {
    'default':   'audio/kelly_default.wav',
    'happy':     'audio/kelly_happy.wav',
    'sad':       'audio/kelly_sad.wav',
    'excited':   'audio/kelly_excited.wav',
    'concerned': 'audio/kelly_concerned.wav',
    'surprised': 'audio/kelly_surprised.wav',
    'calm':      'audio/kelly_calm.wav',
  };

  /// Play the ambient tone for the given emotion.
  /// Fails silently if the asset doesn't exist yet.
  Future<void> playEmotionSound(String emotion) async {
    if (_isMuted) return;

    final assetPath = _emotionSounds[emotion] ?? _emotionSounds['default']!;

    try {
      await _player.stop();
      await _player.setVolume(0.30);
      await _player.setSource(AssetSource(assetPath));
      await _player.resume();
    } catch (e) {
      // Gracefully handle missing audio files during development
      debugPrint('KellySoundService: Could not play $assetPath — $e');
    }
  }

  /// Toggle mute state.
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) _player.stop();
  }

  bool get isMuted => _isMuted;

  /// Release resources.
  void dispose() {
    _player.dispose();
  }
}
