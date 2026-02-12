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

  static Stream<WatchEvent>? _voiceStream;

  /// Stream of voice messages received from Apple Watch.
  static Stream<WatchEvent> get onWatchEvent {
    _voiceStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      final type = map['type'] as String? ?? 'voice';
      if (type == 'textCommand') {
        return WatchTextCommandEvent(
          text: map['text'] as String,
          timestamp: (map['timestamp'] as num).toDouble(),
        );
      }
      return WatchVoiceEvent(
        filePath: map['filePath'] as String,
        timestamp: (map['timestamp'] as num).toDouble(),
      );
    });
    return _voiceStream!;
  }

  /// Stream of voice messages received from Apple Watch.
  @Deprecated('Use onWatchEvent instead')
  static Stream<WatchVoiceEvent> get onVoiceReceived {
    return onWatchEvent.where((e) => e is WatchVoiceEvent).cast<WatchVoiceEvent>();
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

/// Base class for events received from Apple Watch.
abstract class WatchEvent {
  final double timestamp;
  const WatchEvent({required this.timestamp});
}

/// Voice event received from Apple Watch.
class WatchVoiceEvent extends WatchEvent {
  final String filePath;

  const WatchVoiceEvent({
    required this.filePath,
    required super.timestamp,
  });

  @override
  String toString() => 'WatchVoiceEvent(filePath: $filePath, timestamp: $timestamp)';
}

/// Text command event received from Apple Watch.
class WatchTextCommandEvent extends WatchEvent {
  final String text;

  const WatchTextCommandEvent({
    required this.text,
    required super.timestamp,
  });

  @override
  String toString() => 'WatchTextCommandEvent(text: $text, timestamp: $timestamp)';
}
