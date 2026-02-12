import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'recording_state.dart';

/// Service for voice recording management.
///
/// Uses the `record` package to capture audio as m4a files.
class VoiceService {
  final _stateController = StreamController<RecordingState>.broadcast();
  RecordingState _currentState = RecordingState.idle;
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;
  final AudioRecorder _recorder = AudioRecorder();

  /// Stream of recording state changes.
  Stream<RecordingState> get recordingState => _stateController.stream;

  /// Current recording state.
  RecordingState get currentState => _currentState;

  /// Start recording audio as m4a.
  Future<void> startRecording() async {
    if (_currentState == RecordingState.recording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/chatclaw_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );

    _currentRecordingPath = path;
    _recordingStartTime = DateTime.now();
    _currentState = RecordingState.recording;
    _stateController.add(_currentState);
  }

  /// Stop recording and return the local file path.
  Future<String> stopRecording() async {
    if (_currentState != RecordingState.recording) return '';

    _currentState = RecordingState.processing;
    _stateController.add(_currentState);

    final path = await _recorder.stop();
    final result = path ?? _currentRecordingPath ?? '';

    _currentState = RecordingState.idle;
    _stateController.add(_currentState);
    _recordingStartTime = null;
    _currentRecordingPath = null;

    return result;
  }

  /// Get the current recording duration.
  Future<Duration> getRecordingDuration() async {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Dispose resources.
  void dispose() {
    _recorder.dispose();
    _stateController.close();
  }
}
