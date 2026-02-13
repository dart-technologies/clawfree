import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// A voice event received from the Apple Watch via WCSession or gateway relay.
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

  /// Event type: `"voice"` (file), `"voice_command"` (text), or `"ai_reply"`.
  final String type;

  /// Whether this is a text-based voice command (speech recognized on Watch).
  bool get isTextCommand => type == 'voice_command' && text != null;

  factory WatchVoiceEvent.fromMap(Map<dynamic, dynamic> map) {
    return WatchVoiceEvent(
      filePath: map['filePath'] as String?,
      text: map['text'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt())
          : DateTime.now(),
      type: map['type'] as String? ?? 'voice',
    );
  }

  Map<String, dynamic> toJson() => {
        if (filePath != null) 'filePath': filePath,
        if (text != null) 'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'type': type,
      };
}

/// Bidirectional bridge between Flutter and the Apple Watch.
///
/// On iPhone: uses WCSession via platform channels (direct Watch connection).
/// On iPad/other: falls back to gateway SSE relay for Watch communication.
class WatchBridge {
  WatchBridge._();

  static const _methodChannel = MethodChannel('art.dart.clawfree/watch');
  static const _eventChannel = EventChannel('art.dart.clawfree/watch_events');

  /// Gateway base URL for relay mode (set by ChatScreen on init).
  static String? _gatewayBaseUrl;

  /// Whether we're using gateway relay (iPad) vs direct WCSession (iPhone).
  static bool _useRelay = false;

  static StreamController<WatchVoiceEvent>? _relayController;
  static http.Client? _sseClient;

  /// Initialize the bridge. Call once at app startup.
  ///
  /// On iPhone, [gatewayUrl] is used to also broadcast Watch events to the
  /// relay so iPads can receive them. On iPad, it's used as the sole
  /// communication channel.
  static void configure({required String gatewayUrl}) {
    _gatewayBaseUrl = gatewayUrl;

    if (kIsWeb) return;

    if (Platform.isIOS) {
      // Detect iPhone vs iPad — iPhone has WCSession, iPad doesn't
      _checkDeviceAndStartRelay();
    } else if (Platform.isMacOS) {
      // macOS doesn't support WCSession — always use gateway relay
      _useRelay = true;
      _startRelaySubscription();
    }
  }

  static Future<void> _checkDeviceAndStartRelay() async {
    try {
      await _methodChannel.invokeMethod<bool>('isWatchReachable');
      // If the method channel works, we're on iPhone (WCSession available)
      _useRelay = false;
      // iPhone also subscribes to relay for iPad→Watch forwarding
      _startIPhoneRelayListener();
    } on MissingPluginException {
      // WCSession not available — we're on iPad or unsupported platform
      _useRelay = true;
      _startRelaySubscription();
    } on PlatformException {
      _useRelay = true;
      _startRelaySubscription();
    }
  }

  /// iPhone subscribes to relay to pick up iPad commands and forward to Watch.
  static http.Client? _iphoneRelayClient;

  static void _startIPhoneRelayListener() {
    if (_gatewayBaseUrl == null) return;
    _connectSSEWith(
      clientHolder: (c) => _iphoneRelayClient = c,
      onEvent: (map) {
        // Only handle events from iPad destined for Watch
        if (map['source'] == 'ipad' && map['type'] == 'ai_reply') {
          final text = map['text'] as String?;
          if (text != null && text.isNotEmpty) {
            _methodChannel.invokeMethod('sendReply', {'text': text});
          }
        }
      },
      reconnect: _startIPhoneRelayListener,
    );
  }

  /// Subscribe to gateway SSE for Watch events (iPad mode).
  static void _startRelaySubscription() {
    if (_gatewayBaseUrl == null) return;
    _relayController?.close();
    _relayController = StreamController<WatchVoiceEvent>.broadcast();

    _connectSSEWith(
      clientHolder: (c) => _sseClient = c,
      onEvent: (map) {
        _relayController?.add(WatchVoiceEvent.fromMap(map));
      },
      reconnect: _startRelaySubscription,
    );
  }

  /// Generic SSE connector. [onEvent] fires for each parsed relay event.
  /// [reconnect] is called after a 2s delay on disconnect.
  static Future<void> _connectSSEWith({
    required void Function(http.Client) clientHolder,
    required void Function(Map<String, dynamic>) onEvent,
    required void Function() reconnect,
  }) async {
    final url = '$_gatewayBaseUrl/watch/relay';
    try {
      final client = http.Client();
      clientHolder(client);
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (!line.startsWith('data: ')) return;
          final json = line.substring(6);
          try {
            final map = jsonDecode(json) as Map<String, dynamic>;
            if (map['type'] == 'connected') return; // skip handshake
            onEvent(map);
          } catch (_) {}
        },
        onDone: () => Future.delayed(const Duration(seconds: 2), reconnect),
        onError: (_) => Future.delayed(const Duration(seconds: 2), reconnect),
      );
    } catch (_) {
      Future.delayed(const Duration(seconds: 2), reconnect);
    }
  }

  /// Stream of voice events received from the Watch.
  ///
  /// On iPhone: direct from WCSession via EventChannel.
  /// On iPad: from gateway relay SSE stream.
  static Stream<WatchVoiceEvent> get onVoiceReceived {
    if (_useRelay && _relayController != null) {
      return _relayController!.stream;
    }
    return _eventChannel.receiveBroadcastStream().map((event) {
      return WatchVoiceEvent.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  /// Sends an AI reply string back to the Watch for display.
  ///
  /// On iPhone: direct via WCSession MethodChannel.
  /// On iPad: POST to gateway relay, iPhone picks it up and forwards to Watch.
  static Future<void> sendReplyToWatch(String text) async {
    if (_useRelay) {
      await _postToRelay({
        'type': 'ai_reply',
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'ipad',
      });
    } else {
      await _methodChannel.invokeMethod('sendReply', {'text': text});
    }
  }

  /// Broadcast a Watch event to the gateway relay (called by iPhone).
  ///
  /// This lets iPads and other devices see Watch events in real-time.
  static Future<void> broadcastToRelay(WatchVoiceEvent event) async {
    if (_gatewayBaseUrl == null) return;
    await _postToRelay({
      ...event.toJson(),
      'source': 'iphone',
    });
  }

  /// Returns `true` if the paired Watch is currently reachable.
  static Future<bool> get isWatchReachable async {
    if (_useRelay) {
      // In relay mode, we can't directly check — assume reachable if gateway
      // relay is connected.
      return _relayController != null && !(_relayController!.isClosed);
    }
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isWatchReachable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _postToRelay(Map<String, dynamic> data) async {
    if (_gatewayBaseUrl == null) return;
    try {
      await http.post(
        Uri.parse('$_gatewayBaseUrl/watch/relay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (_) {
      // Relay POST failed — non-critical, don't crash
    }
  }

  /// Clean up resources.
  static void dispose() {
    _sseClient?.close();
    _iphoneRelayClient?.close();
    _relayController?.close();
    _relayController = null;
  }
}
