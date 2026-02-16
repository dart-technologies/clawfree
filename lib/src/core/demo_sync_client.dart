import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Demo 同步客戶端：透過 WebSocket 接收 Watch 發送的訊息
///
/// 連線到本地 demo_sync_server.py，接收廣播的聊天訊息。
/// iPhone 和 macOS 都使用此客戶端同步展示 Watch 的對話。
class DemoSyncClient extends ChangeNotifier {
  DemoSyncClient({
    this.serverUrl = 'ws://localhost:8080/ws',
  });

  final String serverUrl;

  WebSocket? _ws;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connected = false;

  /// 是否已連線
  bool get isConnected => _connected;

  /// 收到的訊息串流
  final _messageController = StreamController<DemoSyncMessage>.broadcast();
  Stream<DemoSyncMessage> get onMessage => _messageController.stream;

  /// genUI 觸發事件串流（關鍵字匹配後廣播）
  final _triggerController = StreamController<GenUITriggerAction>.broadcast();
  Stream<GenUITriggerAction> get onGenUITrigger => _triggerController.stream;

  /// 連線到同步伺服器
  Future<void> connect() async {
    if (_disposed) return;
    try {
      debugPrint('[DemoSync] 正在連線到 $serverUrl ...');
      _ws = await WebSocket.connect(serverUrl)
          .timeout(const Duration(seconds: 5));
      _connected = true;
      notifyListeners();
      debugPrint('[DemoSync] ✅ 已連線');

      _ws!.listen(
        (data) {
          if (data is String) {
            _handleMessage(data);
          }
        },
        onDone: () {
          debugPrint('[DemoSync] 🔌 連線已關閉');
          _connected = false;
          notifyListeners();
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('[DemoSync] ❌ 錯誤: $error');
          _connected = false;
          notifyListeners();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[DemoSync] ❌ 連線失敗: $e');
      _connected = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  /// 處理收到的訊息
  void _handleMessage(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String? ?? '';

      if (type == 'chat_message') {
        final msg = DemoSyncMessage(
          text: json['text'] as String? ?? '',
          isUser: json['isUser'] as bool? ?? true,
          source: json['source'] as String? ?? 'unknown',
          timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
        debugPrint('[DemoSync] 📨 收到訊息: "${msg.text.length > 60 ? '${msg.text.substring(0, 60)}...' : msg.text}"');
        _messageController.add(msg);

        // 檢查是否匹配 genUI 觸發關鍵字
        if (msg.isUser) {
          final trigger = _matchTrigger(msg.text);
          if (trigger != null) {
            debugPrint('[DemoSync] 🎯 觸發 genUI 動作: $trigger');
            _triggerController.add(trigger);
          }
        }
      } else if (type == 'system') {
        debugPrint('[DemoSync] 系統訊息: ${json['text']}');
      }
    } catch (e) {
      debugPrint('[DemoSync] ❌ 解析訊息失敗: $e');
    }
  }

  /// 自動重連（每 3 秒嘗試一次）
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) connect();
    });
  }

  /// 斷線並釋放資源
  void disconnect() {
    _reconnectTimer?.cancel();
    _ws?.close();
    _ws = null;
    _connected = false;
    notifyListeners();
  }

  /// 比對訊息文字是否包含 genUI 觸發關鍵字
  GenUITriggerAction? _matchTrigger(String text) {
    final lower = text.toLowerCase().trim();
    for (final entry in _keywordTriggers.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
    _triggerController.close();
    super.dispose();
  }
}

/// genUI 觸發事件類型（Watch 關鍵字 → genUI 狀態推進）
enum GenUITriggerAction {
  /// "OK, confirm" → 確認 Agent 配置並儲存
  confirmAgent,

  /// "Generate Itinerary" → 產生行程
  generateItinerary,

  /// "Book Trip" → 預訂行程
  bookTrip,
}

/// 關鍵字→genUI 動作的映射表
const _keywordTriggers = <String, GenUITriggerAction>{
  'ok, confirm': GenUITriggerAction.confirmAgent,
  'ok confirm': GenUITriggerAction.confirmAgent,
  'confirm': GenUITriggerAction.confirmAgent,
  'generate itinerary': GenUITriggerAction.generateItinerary,
  'generate the itinerary': GenUITriggerAction.generateItinerary,
  'book trip': GenUITriggerAction.bookTrip,
  'book the trip': GenUITriggerAction.bookTrip,
};

/// 從同步伺服器收到的訊息
class DemoSyncMessage {
  const DemoSyncMessage({
    required this.text,
    required this.isUser,
    required this.source,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final String source;
  final DateTime timestamp;
}
