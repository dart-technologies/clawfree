import 'package:flutter/foundation.dart';

/// Source of a voice/text input.
enum InputSource { phone, watch }

/// Current state of the AI interaction pipeline.
enum PipelineState { idle, recording, processing, responding }

/// Tracks which device is actively using the AI pipeline and coordinates
/// overlapping requests from phone and watch.
///
/// Policy: first-come-first-served. Late arrivals are queued (max 1 per source).
/// When the AI finishes responding, the queued item is auto-submitted.
class InputCoordinator extends ChangeNotifier {
  PipelineState _state = PipelineState.idle;
  InputSource? _activeSource;
  _QueuedInput? _queuedInput;

  PipelineState get state => _state;
  InputSource? get activeSource => _activeSource;
  InputSource? get queuedSource => _queuedInput?.source;

  bool get isWatchActive => _activeSource == InputSource.watch;
  bool get isPhoneActive => _activeSource == InputSource.phone;
  bool get hasQueuedInput => _queuedInput != null;

  /// Attempt to claim the pipeline for recording from [source].
  /// Returns true if granted, false if pipeline is busy.
  bool requestAccess(InputSource source) {
    if (_state == PipelineState.idle) {
      _activeSource = source;
      _state = PipelineState.recording;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Submit text from [source]. If pipeline is idle or owned by this source,
  /// returns the text for immediate send. Otherwise queues it and returns null.
  String? submit(InputSource source, String text) {
    if (_state == PipelineState.idle || _activeSource == source) {
      _activeSource = source;
      _state = PipelineState.processing;
      notifyListeners();
      return text;
    }
    // Queue the input (replace any existing queue for this source)
    _queuedInput = _QueuedInput(source: source, text: text);
    notifyListeners();
    return null;
  }

  /// Called when AI starts streaming a response.
  void markResponding() {
    if (_state == PipelineState.processing) {
      _state = PipelineState.responding;
      notifyListeners();
    }
  }

  /// Called when AI response is fully complete.
  /// Returns queued (source, text) if any, or null.
  (InputSource, String)? markComplete() {
    _state = PipelineState.idle;
    _activeSource = null;
    final queued = _queuedInput;
    _queuedInput = null;
    notifyListeners();
    if (queued != null) {
      return (queued.source, queued.text);
    }
    return null;
  }

  /// Cancel the current interaction.
  void cancel() {
    _state = PipelineState.idle;
    _activeSource = null;
    _queuedInput = null;
    notifyListeners();
  }
}

class _QueuedInput {
  const _QueuedInput({required this.source, required this.text});
  final InputSource source;
  final String text;
}
