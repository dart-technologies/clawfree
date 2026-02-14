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
  final _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 從 client 裝置收到的訊息 stream（供 host 處理）。
  Stream<Map<String, dynamic>> get incomingMessages =>
      _incomingController.stream;

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
        (data) => _handleClientMessage(ws, data),
        onDone: () => _removeClient(ws),
        onError: (_) => _removeClient(ws),
      );
    } catch (e) {
      debugPrint('[LocalSyncServer] upgrade error: $e');
    }
  }

  /// 處理來自 client 的訊息，轉發給其他 clients 並通知 host。
  void _handleClientMessage(WebSocket sender, dynamic rawData) {
    try {
      final map = jsonDecode(rawData as String) as Map<String, dynamic>;
      debugPrint('[LocalSyncServer] received from client: ${map['type']}');

      // 通知 host（透過 stream）
      _incomingController.add(map);

      // 轉發給其他 clients（排除發送者）
      final json = jsonEncode(map);
      final dead = <WebSocket>[];
      for (final ws in _clients) {
        if (ws == sender) continue;
        try {
          ws.add(json);
        } catch (_) {
          dead.add(ws);
        }
      }
      for (final ws in dead) {
        _removeClient(ws);
      }
    } catch (e) {
      debugPrint('[LocalSyncServer] client message parse error: $e');
    }
  }

  void _removeClient(WebSocket ws) {
    _clients.remove(ws);
    debugPrint('[LocalSyncServer] client disconnected (${_clients.length} remaining)');
    notifyListeners();
  }

  /// 廣播原始 JSON 資料到所有 client（Watch UI 狀態同步用）。
  void broadcastRaw(Map<String, dynamic> data) {
    _broadcast(data);
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
    _incomingController.close();
    super.dispose();
  }
}
