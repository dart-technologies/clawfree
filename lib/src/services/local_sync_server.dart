import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Local WebSocket server for multi-device sync.
///
/// Runs on the iPhone (host) and broadcasts chat events to connected
/// iPad/macOS clients on the same LAN.
class LocalSyncServer extends ChangeNotifier {
  LocalSyncServer({this.port = 8765});

  final int port;
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  /// Number of currently connected clients.
  int get clientCount => _clients.length;

  /// Whether the server is running.
  bool get isRunning => _server != null;

  /// Start the WebSocket server.
  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      debugPrint('[LocalSyncServer] listening on port $port');
      _server!.listen(_handleRequest);
      notifyListeners();
    } catch (e) {
      debugPrint('[LocalSyncServer] failed to start: $e');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('WebSocket only')
        ..close();
      return;
    }
    try {
      final ws = await WebSocketTransformer.upgrade(request);
      _clients.add(ws);
      debugPrint('[LocalSyncServer] client connected (${_clients.length} total)');
      notifyListeners();

      ws.listen(
        (_) {}, // clients don't send data in this protocol
        onDone: () => _removeClient(ws),
        onError: (_) => _removeClient(ws),
      );
    } catch (e) {
      debugPrint('[LocalSyncServer] upgrade error: $e');
    }
  }

  void _removeClient(WebSocket ws) {
    _clients.remove(ws);
    debugPrint('[LocalSyncServer] client disconnected (${_clients.length} remaining)');
    notifyListeners();
  }

  /// Broadcast a user message to all connected clients.
  void broadcastUserMessage(String text, {String source = 'keyboard'}) {
    _broadcast({
      'type': 'user_message',
      'text': text,
      'source': source,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Broadcast an AI response to all connected clients.
  void broadcastAiResponse(String text, {String? a2ui}) {
    _broadcast({
      'type': 'ai_response',
      'text': text,
      // ignore: use_null_aware_elements
      if (a2ui != null) 'a2ui': a2ui,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _broadcast(Map<String, dynamic> data) {
    if (_clients.isEmpty) return;
    final json = jsonEncode(data);
    final dead = <WebSocket>[];
    for (final ws in _clients) {
      try {
        ws.add(json);
      } catch (_) {
        dead.add(ws);
      }
    }
    for (final ws in dead) {
      _removeClient(ws);
    }
  }

  /// Stop the server and disconnect all clients.
  Future<void> stop() async {
    for (final ws in _clients) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
