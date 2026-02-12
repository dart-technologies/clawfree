import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Generates and plays short audio earcon tones for mic open/close events.
///
/// Tones are synthesised in-memory as PCM WAV — no asset files needed.
/// Gracefully degrades: all public methods silently catch errors.
class EarconService {
  AudioPlayer? _player;
  BytesSource? _micOpenSource;
  BytesSource? _micCloseSource;
  BytesSource? _successSource;
  BytesSource? _errorSource;
  BytesSource? _notifySource;

  /// Pre-generate all tone WAV byte arrays.
  Future<void> init() async {
    try {
      _player = AudioPlayer();
      _micOpenSource = BytesSource(
        _generateToneWav(frequency: 880, durationMs: 120, fadeIn: true),
      );
      _micCloseSource = BytesSource(
        _generateToneWav(frequency: 440, durationMs: 100, fadeIn: false),
      );
      // Two-note ascending chime: C5(523Hz) → E5(659Hz)
      _successSource = BytesSource(
        _generateTwoToneWav(freq1: 523, freq2: 659, durationMs: 100),
      );
      // Two-note descending buzz: E4(330Hz) → C4(262Hz)
      _errorSource = BytesSource(
        _generateTwoToneWav(freq1: 330, freq2: 262, durationMs: 120),
      );
      // Single bright ping: A5(880Hz), 80ms
      _notifySource = BytesSource(
        _generateToneWav(frequency: 880, durationMs: 80, fadeIn: true),
      );
    } catch (_) {
      // Audio not available — earcons silently disabled.
    }
  }

  /// Play the mic-open earcon (ascending tone).
  Future<void> playMicOpen() async {
    try {
      if (_player != null && _micOpenSource != null) {
        await _player!.play(_micOpenSource!);
      }
    } catch (_) {}
  }

  /// Play the mic-close earcon (descending tone).
  Future<void> playMicClose() async {
    try {
      if (_player != null && _micCloseSource != null) {
        await _player!.play(_micCloseSource!);
      }
    } catch (_) {}
  }

  /// Play a success chime (ascending two-note).
  Future<void> playSuccess() async {
    try {
      if (_player != null && _successSource != null) {
        await _player!.play(_successSource!);
      }
    } catch (_) {}
  }

  /// Play an error buzz (descending two-note).
  Future<void> playError() async {
    try {
      if (_player != null && _errorSource != null) {
        await _player!.play(_errorSource!);
      }
    } catch (_) {}
  }

  /// Play a notification ping.
  Future<void> playNotification() async {
    try {
      if (_player != null && _notifySource != null) {
        await _player!.play(_notifySource!);
      }
    } catch (_) {}
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  /// Builds a 16-bit mono PCM WAV in memory.
  Uint8List _generateToneWav({
    required double frequency,
    required int durationMs,
    required bool fadeIn,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Sine wave
      var sample = math.sin(2 * math.pi * frequency * t);
      // Envelope
      final progress = i / numSamples;
      if (fadeIn) {
        // Quick fade-in envelope
        sample *= math.min(progress * 4, 1.0);
      } else {
        // Fade-out envelope
        sample *= math.max(1.0 - progress, 0.0);
      }
      // Scale to 16-bit and apply volume (0.3 to keep it subtle)
      pcm[i] = (sample * 0.3 * 32767).round().clamp(-32768, 32767);
    }

    return _encodeWav(pcm, sampleRate);
  }

  /// Builds a two-tone WAV (two frequencies concatenated).
  Uint8List _generateTwoToneWav({
    required double freq1,
    required double freq2,
    required int durationMs,
  }) {
    const sampleRate = 44100;
    final samplesPerTone = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(samplesPerTone * 2);

    for (var tone = 0; tone < 2; tone++) {
      final freq = tone == 0 ? freq1 : freq2;
      final offset = tone * samplesPerTone;
      for (var i = 0; i < samplesPerTone; i++) {
        final t = i / sampleRate;
        var sample = math.sin(2 * math.pi * freq * t);
        // Fade-out envelope for each tone segment
        final progress = i / samplesPerTone;
        sample *= math.max(1.0 - progress * 0.5, 0.0);
        pcm[offset + i] = (sample * 0.3 * 32767).round().clamp(-32768, 32767);
      }
    }

    return _encodeWav(pcm, sampleRate);
  }

  /// Wraps raw PCM samples in a valid RIFF WAV header.
  Uint8List _encodeWav(Int16List samples, int sampleRate) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = samples.length * blockAlign;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    void writeString(String s) {
      for (var i = 0; i < s.length; i++) {
        buffer.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    void writeUint32(int v) {
      buffer.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    void writeUint16(int v) {
      buffer.setUint16(offset, v, Endian.little);
      offset += 2;
    }

    // RIFF header
    writeString('RIFF');
    writeUint32(fileSize);
    writeString('WAVE');

    // fmt chunk
    writeString('fmt ');
    writeUint32(16); // chunk size
    writeUint16(1); // PCM format
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(blockAlign);
    writeUint16(bitsPerSample);

    // data chunk
    writeString('data');
    writeUint32(dataSize);

    for (final sample in samples) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
