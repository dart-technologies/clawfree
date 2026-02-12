import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Exception thrown by [GatewayClient] on non-2xx responses or network errors.
class GatewayException implements Exception {
  const GatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'GatewayException($message, statusCode: $statusCode)';
}

/// Parsed response from the gateway `/health` endpoint.
class GatewayHealthResponse {
  const GatewayHealthResponse({
    required this.status,
    required this.version,
    required this.uptimeSeconds,
    required this.agents,
    required this.channels,
    required this.latencyMs,
  });

  factory GatewayHealthResponse.fromJson(Map<String, dynamic> json) {
    return GatewayHealthResponse(
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '',
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toInt() ?? 0,
      agents: (json['agents'] as num?)?.toInt() ?? 0,
      channels: (json['channels'] as Map<String, dynamic>?) ?? const {},
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
    );
  }

  final String status;
  final String version;
  final int uptimeSeconds;
  final int agents;
  final Map<String, dynamic> channels;
  final int latencyMs;
}

/// HTTP client for communicating with the OpenClaw gateway.
class GatewayClient extends ChangeNotifier {
  GatewayClient({
    required String baseUrl,
    String token = '',
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _token = token,
        _httpClient = httpClient ?? http.Client();

  String _baseUrl;
  String _token;
  final http.Client _httpClient;

  bool _isConnected = false;

  /// Whether the last health check returned 200.
  bool get isConnected => _isConnected;

  /// The current gateway base URL.
  String get baseUrl => _baseUrl;

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_token.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  /// Update the gateway base URL. Resets connection state.
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _isConnected = false;
    notifyListeners();
  }

  /// Update the auth token.
  void updateToken(String token) {
    _token = token;
    notifyListeners();
  }

  /// GET `/health` — returns parsed health response.
  Future<GatewayHealthResponse> health() async {
    final uri = Uri.parse('$_baseUrl/health');
    try {
      final response = await _httpClient
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _isConnected = true;
        notifyListeners();
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GatewayHealthResponse.fromJson(json);
      }
      _isConnected = false;
      notifyListeners();
      throw GatewayException(
        'Health check failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is GatewayException) rethrow;
      _isConnected = false;
      notifyListeners();
      throw GatewayException('Health check error: $e');
    }
  }

  /// GET `/agents` — returns list of agent configs.
  /// Handles both bare list `[...]` and wrapped `{"agents": [...]}` responses.
  Future<List<Map<String, dynamic>>> fetchAgents() async {
    final uri = Uri.parse('$_baseUrl/agents');
    final response = await _httpClient
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw GatewayException(
        'Fetch agents failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    if (decoded is Map<String, dynamic> && decoded['agents'] is List) {
      return (decoded['agents'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// GET `/sessions` — returns list of connected remote sessions.
  /// Handles both bare list `[...]` and wrapped `{"sessions": [...]}` responses.
  Future<List<Map<String, dynamic>>> fetchSessions() async {
    final uri = Uri.parse('$_baseUrl/sessions');
    final response = await _httpClient
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw GatewayException(
        'Fetch sessions failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    if (decoded is Map<String, dynamic> && decoded['sessions'] is List) {
      return (decoded['sessions'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// POST `/onboard` — trigger gateway onboarding.
  Future<Map<String, dynamic>> onboard({String? apiKey}) async {
    final uri = Uri.parse('$_baseUrl/onboard');
    final body = <String, dynamic>{
      'mode': 'anthropic',
      'auth': 'key',
      'install_daemon': true,
      'non_interactive': true,
    };
    if (apiKey != null && apiKey.isNotEmpty) {
      body['api_key'] = apiKey;
    }
    final response = await _httpClient
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw GatewayException(
        'Onboard failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
