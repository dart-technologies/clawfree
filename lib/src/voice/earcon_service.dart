import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Generates and plays short audio earcon tones for mic open/close events.
///
/// Tones are synthesised in-memory as PCM WAV and written to temporary files
/// to ensure compatibility with platform players (specifically macOS/iOS AVPlayer).
/// Gracefully degrades: all public methods silently catch errors.
class EarconService {
  AudioPlayer? _player;
  Source? _micOpenSource;
  Source? _micCloseSource;
  Source? _successSource;
  Source? _errorSource;
  Source? _notifySource;
  Source? _bookingConfirmSource;

  /// Pre-generate all tone WAV files.
  Future<void> init() async {
    try {
      _player = AudioPlayer();
      // Auto-stop after each sound finishes so stop() is never needed
      // before play(). Avoids "duplicate response" platform channel error.
      await _player!.setReleaseMode(ReleaseMode.stop);

      // Use a timeout to prevent hanging in restricted or unmocked environments.
      final tempDir = await getTemporaryDirectory().timeout(
        const Duration(milliseconds: 500),
      );

      _micOpenSource = await _prepareSource(
        tempDir,
        'mic_open.wav',
        _generateToneWav(
          frequency: 660,
          durationMs: 150,
          fadeIn: true,
          volume: 0.15,
        ),
      );
      _micCloseSource = await _prepareSource(
        tempDir,
        'mic_close.wav',
        _generateToneWav(
          frequency: 392,
          durationMs: 120,
          fadeIn: false,
          volume: 0.12,
        ),
      );
      _successSource = await _prepareSource(
        tempDir,
        'success.wav',
        _generateTwoToneWav(
          freq1: 440,
          freq2: 554,
          durationMs: 120,
          volume: 0.15,
        ),
      );
      _errorSource = await _prepareSource(
        tempDir,
        'error.wav',
        _generateTwoToneWav(
          freq1: 294,
          freq2: 247,
          durationMs: 140,
          volume: 0.12,
        ),
      );
      _notifySource = await _prepareSource(
        tempDir,
        'notify.wav',
        _generateToneWav(
          frequency: 660,
          durationMs: 100,
          fadeIn: true,
          volume: 0.12,
        ),
      );
      _bookingConfirmSource = await _prepareSource(
        tempDir,
        'booking_confirm.wav',
        _generateThreeToneWav(
          freq1: 440,
          freq2: 554,
          freq3: 659,
          durationMs: 100,
          volume: 0.15,
        ),
      );
    } catch (_) {
      // Audio not available or directory restricted — earcons silently disabled.
    }
  }

  /// Writes bytes to a temp file and returns a DeviceFileSource.
  Future<Source> _prepareSource(
    Directory dir,
    String fileName,
    Uint8List bytes,
  ) async {
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return DeviceFileSource(file.path);
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

  /// Play an ascending C-E-G booking confirmation chord.
  Future<void> playBookingConfirm() async {
    try {
      if (_player != null && _bookingConfirmSource != null) {
        await _player!.play(_bookingConfirmSource!);
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
    double volume = 0.15,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Sine wave
      var sample = math.sin(2 * math.pi * frequency * t);
      // Smooth envelope: gentle fade-in and fade-out for calming sound
      final progress = i / numSamples;
      if (fadeIn) {
        final attack = math.min(progress * 3, 1.0);
        final release = math
            .max(1.0 - (progress - 0.6) / 0.4, 0.0)
            .clamp(0.0, 1.0);
        sample *= attack * release;
      } else {
        // Smooth fade-out
        sample *= math.pow(1.0 - progress, 1.5);
      }
      pcm[i] = (sample * volume * 32767).round().clamp(-32768, 32767);
    }

    return _encodeWav(pcm, sampleRate);
  }

  /// Builds a three-tone WAV (ascending chord).
  Uint8List _generateThreeToneWav({
    required double freq1,
    required double freq2,
    required double freq3,
    required int durationMs,
    double volume = 0.15,
  }) {
    const sampleRate = 44100;
    final samplesPerTone = (sampleRate * durationMs / 1000).round();
    final pcm = Int16List(samplesPerTone * 3);

    final freqs = [freq1, freq2, freq3];
    for (var tone = 0; tone < 3; tone++) {
      final freq = freqs[tone];
      final offset = tone * samplesPerTone;
      for (var i = 0; i < samplesPerTone; i++) {
        final t = i / sampleRate;
        var sample = math.sin(2 * math.pi * freq * t);
        // Smooth fade-out envelope for calming feel
        final progress = i / samplesPerTone;
        sample *= math.pow(1.0 - progress * 0.6, 1.5).clamp(0.0, 1.0);
        // Gentle volume increase per tone
        final toneVol = volume + 0.02 * tone;
        pcm[offset + i] = (sample * toneVol * 32767).round().clamp(
          -32768,
          32767,
        );
      }
    }

    return _encodeWav(pcm, sampleRate);
  }

  /// Builds a two-tone WAV (two frequencies concatenated).
  Uint8List _generateTwoToneWav({
    required double freq1,
    required double freq2,
    required int durationMs,
    double volume = 0.15,
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
        // Smooth fade-out for calming sound
        final progress = i / samplesPerTone;
        sample *= math.pow(1.0 - progress * 0.6, 1.5).clamp(0.0, 1.0);
        pcm[offset + i] = (sample * volume * 32767).round().clamp(
          -32768,
          32767,
        );
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
