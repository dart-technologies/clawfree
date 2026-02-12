import 'dart:async';
import 'package:flutter/services.dart';

/// Bridge between Flutter and Apple Watch via WatchConnectivity.
///
/// - Receives voice files from Watch (via EventChannel)
/// - Sends AI replies back to Watch (via MethodChannel)
class WatchBridge {
  static const _methodChannel =
      MethodChannel('com.rollbytes.chatclaw/watch');
  static const _eventChannel =
      EventChannel('com.rollbytes.chatclaw/watch_events');

  static Stream<WatchVoiceEvent>? _voiceStream;

  /// Stream of voice messages received from Apple Watch.
  static Stream<WatchVoiceEvent> get onVoiceReceived {
    _voiceStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return WatchVoiceEvent(
        filePath: map['filePath'] as String,
        timestamp: (map['timestamp'] as num).toDouble(),
      );
    });
    return _voiceStream!;
  }

  /// Send AI reply text back to Watch for display.
  static Future<void> sendReplyToWatch(String text) async {
    await _methodChannel.invokeMethod('sendReply', {'text': text});
  }

  /// Check if Watch is currently reachable.
  static Future<bool> get isWatchReachable async {
    final result = await _methodChannel.invokeMethod<bool>('isWatchReachable');
    return result ?? false;
  }
}

/// Voice event received from Apple Watch.
class WatchVoiceEvent {
  final String filePath;
  final double timestamp;

  const WatchVoiceEvent({
    required this.filePath,
    required this.timestamp,
  });

  @override
  String toString() => 'WatchVoiceEvent(filePath: $filePath, timestamp: $timestamp)';
}
