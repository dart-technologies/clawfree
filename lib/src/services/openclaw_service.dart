import 'dart:math';
import 'package:dio/dio.dart';

/// Service to communicate with OpenClaw Gateway (OpenAI-compatible chat completions).
class OpenClawService {
  final String apiKey;
  final String? gatewayUrl;
  final String? gatewayToken;
  final Dio _dio = Dio();

  OpenClawService({
    required this.apiKey,
    this.gatewayUrl,
    this.gatewayToken,
  });

  /// Create instance from dart-define environment variables.
  /// Priority: OpenClaw Gateway > Direct Anthropic API > Mock mode.
  factory OpenClawService.demo() {
    const apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
    const gwUrl = String.fromEnvironment('OPENCLAW_GATEWAY_URL');
    const gwToken = String.fromEnvironment('OPENCLAW_GATEWAY_TOKEN');
    return OpenClawService(
      apiKey: apiKey,
      gatewayUrl: gwUrl.isNotEmpty ? gwUrl : null,
      gatewayToken: gwToken.isNotEmpty ? gwToken : null,
    );
  }

  bool get _hasGateway => gatewayUrl != null && gatewayUrl!.isNotEmpty;
  bool get _hasApiKey => apiKey.isNotEmpty;
  bool get isConnected => _hasGateway || _hasApiKey;
  String get mode => _hasGateway ? 'OpenClaw Gateway' : _hasApiKey ? 'Anthropic API' : 'Mock';

  /// Send a text message and get AI response.
  Future<String> sendMessage(String text) async {
    // Priority 1: OpenClaw Gateway
    if (_hasGateway) {
      return _sendViaGateway(text);
    }
    // Priority 2: Direct Anthropic API
    if (_hasApiKey) {
      return _sendViaAnthropic(text);
    }
    // Priority 3: Smart mock
    return _smartMockResponse(text);
  }

  /// Send a voice message — sends transcription request text.
  Future<String> sendVoice(String audioFilePath) async {
    return sendMessage('I sent a voice message. Please respond.');
  }

  /// Send via OpenClaw Gateway (OpenAI-compatible chat completions endpoint).
  Future<String> _sendViaGateway(String text) async {
    try {
      final headers = <String, String>{
        'content-type': 'application/json',
      };
      if (gatewayToken != null && gatewayToken!.isNotEmpty) {
        headers['authorization'] = 'Bearer $gatewayToken';
      }

      final response = await _dio.post(
        '$gatewayUrl/v1/chat/completions',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': 'anthropic/claude-sonnet-4-5',
          'messages': [
            {
              'role': 'system',
              'content': 'You are ChatClaw AI assistant. You help users research topics, manage tasks, and capture ideas. Reply in the same language as the user. Be concise and actionable.',
            },
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 1024,
        },
      );

      final choices = response.data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']['content'] as String;
      }
      return '(empty response from OpenClaw)';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      return '❌ OpenClaw Gateway error ($statusCode): $body';
    } catch (e) {
      return '❌ OpenClaw connection error: $e';
    }
  }

  /// Send via direct Anthropic API.
  Future<String> _sendViaAnthropic(String text) async {
    try {
      final response = await _dio.post(
        'https://api.anthropic.com/v1/messages',
        options: Options(headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        }),
        data: {
          'model': 'claude-sonnet-4-5-20250514',
          'max_tokens': 1024,
          'system': 'You are ChatClaw AI assistant. You help users research topics, manage tasks, and capture ideas. Reply in the same language as the user. Be concise and actionable.',
          'messages': [
            {'role': 'user', 'content': text}
          ],
        },
      );

      final content = response.data['content'] as List;
      if (content.isNotEmpty) {
        return content[0]['text'] as String;
      }
      return '(empty response)';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      return '❌ Claude API error ($statusCode): $body';
    }
  }

  /// Smart mock response that simulates real AI research behavior.
  Future<String> _smartMockResponse(String text) async {
    final lower = text.toLowerCase();
    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));

    if (_containsAny(lower, ['調研', '研究', '分析', '方案', '比較', '評估', 'research', 'analyze', 'compare'])) {
      return '🦞 **ChatClaw AI — 調研啟動**\n\n'
          '📋 收到！正在為您調研「${_extractTopic(text)}」\n\n'
          '**初步分析：**\n'
          '1. 📊 市場規模：預估年成長率 15-20%\n'
          '2. 🏢 主要競爭者：3-5 家，各有不同切入角度\n'
          '3. 💡 機會點：目前市場缺乏整合型解決方案\n\n'
          '**建議下一步：**\n'
          '• 深入分析 Top 3 競品的定價策略\n'
          '• 訪談 5 位潛在用戶了解痛點\n'
          '• 製作 MVP 原型進行初步驗證\n\n'
          '_🔍 調研持續中，有新發現會即時更新..._';
    }

    if (_containsAny(lower, ['行程', '排', '會議', '約', '提醒', 'schedule', 'meeting', 'remind'])) {
      return '🦞 **ChatClaw AI — 行程管理**\n\n'
          '✅ 已記錄！\n\n'
          '📅 我已將以下事項加入行程：\n'
          '• **事項：** ${_extractTopic(text)}\n'
          '• **狀態：** 待確認時間\n\n'
          '需要我設定提醒嗎？';
    }

    if (_containsAny(lower, ['待辦', '任務', '做', '處理', '完成', 'todo', 'task', 'do'])) {
      return '🦞 **ChatClaw AI — 任務追蹤**\n\n'
          '📝 已建立任務：\n\n'
          '• **${_extractTopic(text)}**\n'
          '• 優先級：🔴 高\n'
          '• 狀態：進行中\n\n'
          '我會持續追蹤進度，有更新會通知你 💪';
    }

    if (_containsAny(lower, ['想法', '點子', '靈感', '構想', 'idea', 'brainstorm'])) {
      return '🦞 **ChatClaw AI — 靈感捕捉**\n\n'
          '💡 好想法！已記錄：\n\n'
          '「${_extractTopic(text)}」\n\n'
          '**延伸思考：**\n'
          '• 這個方向可以結合 AI 自動化來加速\n'
          '• 建議先做小規模測試驗證可行性\n'
          '• 類似概念在海外市場已有初步驗證\n\n'
          '_已存入想法庫，隨時可以回顧 📚_';
    }

    return '🦞 **ChatClaw AI**\n\n'
        '收到你的訊息！\n\n'
        '「${text.length > 100 ? '${text.substring(0, 100)}...' : text}」\n\n'
        '我可以幫你：\n'
        '• 📊 調研分析任何主題\n'
        '• 📅 管理行程和提醒\n'
        '• 📝 追蹤待辦任務\n'
        '• 💡 記錄和延伸想法\n\n'
        '試試對我說「幫我調研 XXX 方案」👆';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String _extractTopic(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'(幫我|請|幫忙|我要|我想|可以)'), '')
        .replaceAll(RegExp(r'(調研|研究|分析|比較|排|做|處理|記錄)'), '')
        .trim();
    if (cleaned.isEmpty || cleaned.length < 2) return text;
    return cleaned.length > 50 ? '${cleaned.substring(0, 50)}...' : cleaned;
  }
}
