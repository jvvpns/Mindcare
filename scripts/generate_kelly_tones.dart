import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates short synthetic/digital ambient tones for Kelly's emotions.
/// Run with: dart run scripts/generate_kelly_tones.dart
void main() {
  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  // Each tone: name, frequency(s), duration, envelope shape
  final tones = <String, _ToneSpec>{
    'kelly_default': _ToneSpec(
      freqs: [440, 554], // A4 + C#5 — neutral, clean
      durationMs: 600,
      envelope: _Envelope.fadeInOut,
      volume: 0.25,
    ),
    'kelly_happy': _ToneSpec(
      freqs: [523, 659], // C5 + E5 — rising major third
      durationMs: 500,
      envelope: _Envelope.pluck,
      volume: 0.3,
    ),
    'kelly_sad': _ToneSpec(
      freqs: [330, 392], // E4 + G4 — minor feel, low
      durationMs: 900,
      envelope: _Envelope.slowFade,
      volume: 0.2,
    ),
    'kelly_excited': _ToneSpec(
      freqs: [587, 740, 880], // D5 + F#5 + A5 — bright arpeggio
      durationMs: 450,
      envelope: _Envelope.sparkle,
      volume: 0.3,
    ),
    'kelly_concerned': _ToneSpec(
      freqs: [392, 349], // G4 + F4 — descending step
      durationMs: 700,
      envelope: _Envelope.fadeInOut,
      volume: 0.22,
    ),
    'kelly_surprised': _ToneSpec(
      freqs: [880, 1047], // A5 + C6 — quick, high ping
      durationMs: 300,
      envelope: _Envelope.pluck,
      volume: 0.28,
    ),
    'kelly_calm': _ToneSpec(
      freqs: [349, 440], // F4 + A4 — warm, stable
      durationMs: 800,
      envelope: _Envelope.slowFade,
      volume: 0.2,
    ),
  };

  for (final entry in tones.entries) {
    final filename = '${entry.key}.mp3';
    // We'll generate WAV and name it .mp3 for simplicity with audioplayers
    // Actually, let's generate proper WAV files
    final wavFilename = '${entry.key}.mp3';
    final data = _generateWav(entry.value);
    final file = File('${outputDir.path}/${entry.key}.mp3');
    // Generate as WAV with .mp3 extension won't work. Let's use .wav
    final wavFile = File('${outputDir.path}/${entry.key}.wav');
    wavFile.writeAsBytesSync(data);
    print('Generated: ${wavFile.path} (${data.length} bytes)');
  }

  print('\nDone! Generated ${tones.length} tone files.');
  print('Note: Update kelly_sound_service.dart to use .wav extension.');
}

Uint8List _generateWav(_ToneSpec spec) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * spec.durationMs / 1000).round();
  final samples = Float64List(numSamples);

  // Mix all frequencies together
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples; // 0.0 → 1.0

    double sample = 0;
    for (int f = 0; f < spec.freqs.length; f++) {
      final freq = spec.freqs[f].toDouble();
      // Sine wave with slight harmonic overtone for digital character
      sample += sin(2 * pi * freq * t) * 0.7;
      sample += sin(2 * pi * freq * 2 * t) * 0.15; // 2nd harmonic
      sample += sin(2 * pi * freq * 3 * t) * 0.05; // 3rd harmonic (subtle)
    }

    // Normalize by number of frequencies
    sample /= spec.freqs.length;

    // Apply envelope
    final envelope = _applyEnvelope(progress, spec.envelope);
    samples[i] = sample * envelope * spec.volume;
  }

  // Convert to 16-bit PCM
  final pcmData = Int16List(numSamples);
  for (int i = 0; i < numSamples; i++) {
    pcmData[i] = (samples[i] * 32767).round().clamp(-32768, 32767);
  }

  // Build WAV file
  return _buildWav(pcmData, sampleRate);
}

double _applyEnvelope(double progress, _Envelope envelope) {
  switch (envelope) {
    case _Envelope.fadeInOut:
      // Smooth fade in first 20%, hold, fade out last 30%
      if (progress < 0.2) return progress / 0.2;
      if (progress > 0.7) return (1.0 - progress) / 0.3;
      return 1.0;

    case _Envelope.pluck:
      // Quick attack, exponential decay
      if (progress < 0.05) return progress / 0.05;
      return pow(1.0 - progress, 2.5).toDouble();

    case _Envelope.slowFade:
      // Gentle fade in first 30%, very slow fade out
      if (progress < 0.3) return progress / 0.3;
      return pow(1.0 - (progress - 0.3) / 0.7, 1.5).toDouble();

    case _Envelope.sparkle:
      // Multiple quick pulses
      final pulse = sin(progress * pi * 6) * 0.3 + 0.7;
      final decay = pow(1.0 - progress, 1.5);
      return pulse * decay;
  }
}

Uint8List _buildWav(Int16List pcmData, int sampleRate) {
  final dataSize = pcmData.length * 2;
  final fileSize = 44 + dataSize;
  final buffer = ByteData(fileSize);

  // RIFF header
  buffer.setUint8(0, 0x52); // R
  buffer.setUint8(1, 0x49); // I
  buffer.setUint8(2, 0x46); // F
  buffer.setUint8(3, 0x46); // F
  buffer.setUint32(4, fileSize - 8, Endian.little);
  buffer.setUint8(8, 0x57);  // W
  buffer.setUint8(9, 0x41);  // A
  buffer.setUint8(10, 0x56); // V
  buffer.setUint8(11, 0x45); // E

  // fmt chunk
  buffer.setUint8(12, 0x66); // f
  buffer.setUint8(13, 0x6D); // m
  buffer.setUint8(14, 0x74); // t
  buffer.setUint8(15, 0x20); // (space)
  buffer.setUint32(16, 16, Endian.little);     // Chunk size
  buffer.setUint16(20, 1, Endian.little);      // PCM format
  buffer.setUint16(22, 1, Endian.little);      // Mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
  buffer.setUint16(32, 2, Endian.little);      // Block align
  buffer.setUint16(34, 16, Endian.little);     // Bits per sample

  // data chunk
  buffer.setUint8(36, 0x64); // d
  buffer.setUint8(37, 0x61); // a
  buffer.setUint8(38, 0x74); // t
  buffer.setUint8(39, 0x61); // a
  buffer.setUint32(40, dataSize, Endian.little);

  // PCM samples
  for (int i = 0; i < pcmData.length; i++) {
    buffer.setInt16(44 + i * 2, pcmData[i], Endian.little);
  }

  return buffer.buffer.asUint8List();
}

class _ToneSpec {
  final List<int> freqs;
  final int durationMs;
  final _Envelope envelope;
  final double volume;

  const _ToneSpec({
    required this.freqs,
    required this.durationMs,
    required this.envelope,
    required this.volume,
  });
}

enum _Envelope {
  fadeInOut,
  pluck,
  slowFade,
  sparkle,
}
