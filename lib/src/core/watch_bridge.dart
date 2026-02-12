import 'dart:async';

import 'package:flutter/services.dart';

/// A voice event received from the Apple Watch via WCSession.
///
/// Supports both file-based transfers (legacy) and text-based voice commands
/// (speech recognized on Watch, sent as text).
class WatchVoiceEvent {
  WatchVoiceEvent({
    this.filePath,
    this.text,
    required this.timestamp,
    required this.type,
  });

  /// For file-based transfers: local path to the `.m4a` audio.
  final String? filePath;

  /// For text-based voice commands: the recognized speech text.
  final String? text;

  final DateTime timestamp;

  /// Event type: `"voice"` (file) or `"voice_command"` (text).
  final String type;

  /// Whether this is a text-based voice command (speech recognized on Watch).
  bool get isTextCommand => type == 'voice_command' && text != null;

  factory WatchVoiceEvent.fromMap(Map<dynamic, dynamic> map) {
    return WatchVoiceEvent(
      filePath: map['filePath'] as String?,
      text: map['text'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      type: map['type'] as String? ?? 'voice',
    );
  }
}

/// Bidirectional bridge between Flutter and the Apple Watch.
///
/// Uses an [EventChannel] to receive voice events pushed from native
/// (Watch -> iPhone -> Flutter) and a [MethodChannel] to send replies and
/// query reachability (Flutter -> Native -> Watch).
class WatchBridge {
  WatchBridge._();

  static const _methodChannel =
      MethodChannel('art.dart.clawfree/watch');
  static const _eventChannel =
      EventChannel('art.dart.clawfree/watch_events');

  /// Stream of voice events received from the Watch.
  ///
  /// Events can be either file-based (audio `.m4a`) or text-based
  /// (speech recognized on Watch). Check [WatchVoiceEvent.isTextCommand].
  static Stream<WatchVoiceEvent> get onVoiceReceived {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return WatchVoiceEvent.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  /// Sends an AI reply string back to the Watch for display.
  static Future<void> sendReplyToWatch(String text) async {
    await _methodChannel.invokeMethod('sendReply', {'text': text});
  }

  /// Returns `true` if the paired Watch is currently reachable.
  static Future<bool> get isWatchReachable async {
    final result =
        await _methodChannel.invokeMethod<bool>('isWatchReachable');
    return result ?? false;
  }
}
