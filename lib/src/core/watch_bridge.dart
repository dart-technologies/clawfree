import 'dart:async';

import 'package:flutter/services.dart';

/// A voice event received from the Apple Watch via WCSession file transfer.
class WatchVoiceEvent {
  WatchVoiceEvent({required this.filePath, required this.timestamp});

  final String filePath;
  final DateTime timestamp;

  factory WatchVoiceEvent.fromMap(Map<dynamic, dynamic> map) {
    return WatchVoiceEvent(
      filePath: map['filePath'] as String,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
    );
  }
}

/// Bidirectional bridge between Flutter and the Apple Watch.
///
/// Uses an [EventChannel] to receive voice file events pushed from native
/// (Watch -> iPhone -> Flutter) and a [MethodChannel] to send replies and
/// query reachability (Flutter -> Native -> Watch).
class WatchBridge {
  WatchBridge._();

  static const _methodChannel = MethodChannel('art.dart.clawfree/watch');
  static const _eventChannel = EventChannel('art.dart.clawfree/watch_events');

  /// Stream of voice events received from the Watch.
  ///
  /// Each event carries the local file path to the transferred `.m4a` audio
  /// and a timestamp.
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
    final result = await _methodChannel.invokeMethod<bool>('isWatchReachable');
    return result ?? false;
  }
}
