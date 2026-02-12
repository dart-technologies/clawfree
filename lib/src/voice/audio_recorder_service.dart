import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for recording audio to m4a files (press-to-talk).
class AudioRecorderService {
  AudioRecorderService();

  AudioRecorder? _recorder;
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<void> _ensureRecorder() async {
    _recorder ??= AudioRecorder();
  }

  /// Check if recording is supported/permitted.
  Future<bool> get isAvailable async {
    if (kIsWeb) return false;
    await _ensureRecorder();
    return await _recorder!.hasPermission();
  }

  /// Start recording to a temporary m4a file.
  /// Returns the file path that will contain the recording.
  Future<String?> startRecording() async {
    if (_isRecording) return _currentPath;
    await _ensureRecorder();

    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      debugPrint('[AudioRecorder] No microphone permission');
      return null;
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/voice_$timestamp.m4a';

    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      ),
      path: _currentPath!,
    );

    _isRecording = true;
    debugPrint('[AudioRecorder] Recording started: $_currentPath');
    return _currentPath;
  }

  /// Stop recording and return the file path.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder!.stop();
    _isRecording = false;
    debugPrint('[AudioRecorder] Recording stopped: $path');
    return path ?? _currentPath;
  }

  /// Cancel recording and delete the file.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    await _recorder!.stop();
    _isRecording = false;
    if (_currentPath != null) {
      try {
        await File(_currentPath!).delete();
      } catch (_) {}
    }
    _currentPath = null;
  }

  void dispose() {
    _recorder?.dispose();
    _recorder = null;
  }
}
