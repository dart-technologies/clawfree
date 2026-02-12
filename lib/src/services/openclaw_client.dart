import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Client for communicating with OpenClaw Gateway.
///
/// Handles: sending text/audio, receiving responses, device registration.
/// Default endpoint: `http://192.168.68.16:18789` (configurable).
class OpenClawClient extends ChangeNotifier {
  OpenClawClient({
    String baseUrl = 'http://192.168.68.16:18789',
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client();

  String _baseUrl;
  final http.Client _httpClient;

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  /// Send a text message to the gateway and get a response.
  Future<String> sendText(String text, {String? sessionId}) async {
    final uri = Uri.parse('$_baseUrl/v1/chat/completions');
    final payload = <String, dynamic>{
      'messages': [
        {'role': 'user', 'content': text},
      ],
    };
    if (sessionId != null) payload['session_id'] = sessionId;
    final body = jsonEncode(payload);

    try {
      final response = await _httpClient
          .post(uri, headers: _jsonHeaders, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Try OpenAI-compatible format
        final choices = json['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          return message?['content'] as String? ?? '';
        }
        // Fallback: direct response field
        return json['response'] as String? ?? json.toString();
      }
      throw OpenClawException(
        'Send text failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is OpenClawException) rethrow;
      throw OpenClawException('Send text error: $e');
    }
  }

  /// Send an audio file to the gateway for STT + processing.
  Future<String> sendAudio(String filePath, {String? sessionId}) async {
    final uri = Uri.parse('$_baseUrl/v1/audio/transcriptions');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['model'] = 'whisper-1';
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['text'] as String? ?? '';
      }
      throw OpenClawException(
        'Send audio failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is OpenClawException) rethrow;
      throw OpenClawException('Send audio error: $e');
    }
  }

  /// Register this device with the gateway.
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/devices/register');
    final body = jsonEncode({
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'platform': _platformString(),
    });

    try {
      final response = await _httpClient
          .post(uri, headers: _jsonHeaders, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw OpenClawException(
        'Device registration failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is OpenClawException) rethrow;
      throw OpenClawException('Device registration error: $e');
    }
  }

  /// Fetch list of connected devices from gateway.
  Future<List<Map<String, dynamic>>> fetchDevices() async {
    final uri = Uri.parse('$_baseUrl/v1/devices');

    try {
      final response = await _httpClient
          .get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
        if (decoded is Map && decoded['devices'] is List) {
          return (decoded['devices'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      }
      throw OpenClawException(
        'Fetch devices failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is OpenClawException) rethrow;
      throw OpenClawException('Fetch devices error: $e');
    }
  }

  /// Health check.
  Future<bool> ping() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _platformString() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}

class OpenClawException implements Exception {
  const OpenClawException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'OpenClawException($message, statusCode: $statusCode)';
}
