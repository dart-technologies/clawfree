import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Event received from the sync server.
class SyncEvent {
  SyncEvent({required this.type, required this.data});

  /// `user_message` or `ai_response`.
  final String type;
  final Map<String, dynamic> data;

  String get text => data['text'] as String? ?? '';
  String? get a2ui => data['a2ui'] as String?;
  String get source => data['source'] as String? ?? 'unknown';
}

/// WebSocket client that connects to the iPhone sync server.
///
/// Used by iPad and macOS devices to receive real-time chat updates.
class LocalSyncClient extends ChangeNotifier {
  LocalSyncClient({required this.serverUrl});

  final String serverUrl; // e.g. ws://192.168.1.5:8765

  WebSocket? _ws;
  bool _disposed = false;
  bool _connected = false;
  int _retryDelay = 1;

  final _eventController = StreamController<SyncEvent>.broadcast();

  /// Stream of sync events from the server.
  Stream<SyncEvent> get events => _eventController.stream;

  /// Whether currently connected.
  bool get isConnected => _connected;

  /// Connect to the sync server with auto-reconnect.
  Future<void> connect() async {
    if (_disposed) return;
    try {
      _ws = await WebSocket.connect(serverUrl);
      _connected = true;
      _retryDelay = 1;
      debugPrint('[LocalSyncClient] connected to $serverUrl');
      notifyListeners();

      _ws!.listen(
        (data) {
          try {
            final map = jsonDecode(data as String) as Map<String, dynamic>;
            final type = map['type'] as String? ?? '';
            _eventController.add(SyncEvent(type: type, data: map));
          } catch (e) {
            debugPrint('[LocalSyncClient] parse error: $e');
          }
        },
        onDone: () => _onDisconnect(),
        onError: (_) => _onDisconnect(),
      );
    } catch (e) {
      debugPrint('[LocalSyncClient] connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _onDisconnect() {
    _connected = false;
    _ws = null;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    final delay = _retryDelay;
    _retryDelay = min(_retryDelay * 2, 30);
    debugPrint('[LocalSyncClient] reconnecting in ${delay}s...');
    Future.delayed(Duration(seconds: delay), () {
      if (!_disposed) connect();
    });
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    _disposed = true;
    await _ws?.close();
    _ws = null;
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _eventController.close();
    super.dispose();
  }
}
