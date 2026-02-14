import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:clawfree/src/core/gateway_client.dart';

http_testing.MockClient _mockClient(
  Future<http.Response> Function(http.Request) handler,
) {
  return http_testing.MockClient(handler);
}

void main() {
  group('GatewayClient.health', () {
    test('returns GatewayHealthResponse on 200', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': '1.4.2',
            'uptime_seconds': 3600,
            'agents': 3,
            'channels': {'telegram': 'active', 'slack': 'active'},
            'latency_ms': 45,
          }),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final result = await client.health();

      expect(result.status, 'ok');
      expect(result.version, '1.4.2');
      expect(result.uptimeSeconds, 3600);
      expect(result.agents, 3);
      expect(result.channels['telegram'], 'active');
      expect(result.latencyMs, 45);
      expect(client.isConnected, isTrue);
      client.dispose();
    });

    test('throws GatewayException on 500', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.health(),
        throwsA(
          isA<GatewayException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      client.dispose();
    });

    test('throws GatewayException on timeout/network error', () async {
      final mockHttp = _mockClient((request) async {
        throw Exception('Connection refused');
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.health(),
        throwsA(isA<GatewayException>()),
      );
      client.dispose();
    });

    test('sets isConnected false on error', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Bad Gateway', 502);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      try {
        await client.health();
      } catch (_) {}

      expect(client.isConnected, isFalse);
      client.dispose();
    });
  });

  group('GatewayClient.fetchAgents', () {
    test('parses bare list response', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.url.path, '/agents');
        return http.Response(
          jsonEncode([
            {'name': 'Agent1', 'model': 'claude-opus-4-6'},
            {'name': 'Agent2', 'model': 'claude-sonnet-4-5'},
          ]),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final agents = await client.fetchAgents();

      expect(agents, hasLength(2));
      expect(agents[0]['name'], 'Agent1');
      expect(agents[1]['name'], 'Agent2');
      client.dispose();
    });

    test('parses wrapped {"agents": [...]} response', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response(
          jsonEncode({
            'agents': [
              {'name': 'WrappedAgent', 'model': 'gpt-4o'},
            ],
          }),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final agents = await client.fetchAgents();

      expect(agents, hasLength(1));
      expect(agents[0]['name'], 'WrappedAgent');
      client.dispose();
    });

    test('throws on non-200 status', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.fetchAgents(),
        throwsA(
          isA<GatewayException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      client.dispose();
    });
  });

  group('GatewayClient.fetchSessions', () {
    test('parses bare list response', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.url.path, '/sessions');
        return http.Response(
          jsonEncode([
            {
              'session_id': 's1',
              'device_type': 'phone',
              'device_name': "Mike's iPhone",
              'connected_at': '2026-02-12T14:30:00Z',
            },
            {
              'session_id': 's2',
              'device_type': 'watch',
              'device_name': "Mike's Watch",
            },
          ]),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final sessions = await client.fetchSessions();

      expect(sessions, hasLength(2));
      expect(sessions[0]['session_id'], 's1');
      expect(sessions[0]['device_type'], 'phone');
      expect(sessions[1]['session_id'], 's2');
      expect(sessions[1]['device_type'], 'watch');
      client.dispose();
    });

    test('parses wrapped {"sessions": [...]} response', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response(
          jsonEncode({
            'sessions': [
              {
                'session_id': 's3',
                'device_type': 'tablet',
                'device_name': "Roy's iPad",
              },
            ],
          }),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final sessions = await client.fetchSessions();

      expect(sessions, hasLength(1));
      expect(sessions[0]['device_name'], "Roy's iPad");
      client.dispose();
    });

    test('throws on non-200 status', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.fetchSessions(),
        throwsA(
          isA<GatewayException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      client.dispose();
    });
  });

  group('GatewayClient.onboard', () {
    test('sends POST with correct body on success', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/onboard');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['mode'], 'anthropic');
        expect(body['auth'], 'key');
        expect(body['api_key'], 'sk-test');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final result = await client.onboard(apiKey: 'sk-test');

      expect(result['status'], 'ok');
      client.dispose();
    });

    test('throws on non-200 status', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Unauthorized', 401);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.onboard(),
        throwsA(
          isA<GatewayException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      client.dispose();
    });
  });

  group('GatewayClient.createAgent', () {
    test('sends POST with config and returns response on 201', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/agents');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'TestBot');
        expect(body['model'], 'claude-opus-4-6');
        return http.Response(
          jsonEncode({
            'name': 'TestBot',
            'id': 'agent-001',
            'status': 'active',
          }),
          201,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final result = await client.createAgent({
        'name': 'TestBot',
        'model': 'claude-opus-4-6',
        'tools': ['browser'],
        'channels': ['telegram'],
      });

      expect(result['name'], 'TestBot');
      expect(result['id'], 'agent-001');
      client.dispose();
    });

    test('accepts 200 as success', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response(jsonEncode({'name': 'Bot', 'status': 'ok'}), 200);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      final result = await client.createAgent({'name': 'Bot'});
      expect(result['status'], 'ok');
      client.dispose();
    });

    test('throws on 400 Bad Request', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Bad Request', 400);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.createAgent({'name': ''}),
        throwsA(
          isA<GatewayException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
      client.dispose();
    });

    test('throws on 500 Server Error', () async {
      final mockHttp = _mockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await expectLater(
        () => client.createAgent({'name': 'Bot'}),
        throwsA(
          isA<GatewayException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      client.dispose();
    });

    test('includes auth token in request', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer agent-token');
        return http.Response(jsonEncode({'ok': true}), 201);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        token: 'agent-token',
        httpClient: mockHttp,
      );

      await client.createAgent({'name': 'Bot'});
      client.dispose();
    });
  });

  group('GatewayClient.updateBaseUrl', () {
    test('resets isConnected and notifies', () async {
      // First connect successfully
      final mockHttp = _mockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': '1.4.2',
            'uptime_seconds': 100,
            'agents': 0,
            'channels': {},
            'latency_ms': 10,
          }),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await client.health();
      expect(client.isConnected, isTrue);

      int notifyCount = 0;
      client.addListener(() => notifyCount++);

      client.updateBaseUrl('http://new-host:18789');

      expect(client.isConnected, isFalse);
      expect(client.baseUrl, 'http://new-host:18789');
      expect(notifyCount, 1);
      client.dispose();
    });
  });

  group('GatewayClient.updateToken', () {
    test('notifies listeners', () {
      final mockHttp = _mockClient((request) async {
        return http.Response('', 200);
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      int notifyCount = 0;
      client.addListener(() => notifyCount++);

      client.updateToken('new-token');

      expect(notifyCount, 1);
      client.dispose();
    });
  });

  group('GatewayClient headers', () {
    test('includes Authorization when token is set', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer my-token');
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': '1.0',
            'uptime_seconds': 0,
            'agents': 0,
            'channels': {},
            'latency_ms': 0,
          }),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        token: 'my-token',
        httpClient: mockHttp,
      );

      await client.health();
      client.dispose();
    });

    test('omits Authorization when token is empty', () async {
      final mockHttp = _mockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'status': 'ok',
            'version': '1.0',
            'uptime_seconds': 0,
            'agents': 0,
            'channels': {},
            'latency_ms': 0,
          }),
          200,
        );
      });
      final client = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );

      await client.health();
      client.dispose();
    });
  });

  group('GatewayHealthResponse.fromJson', () {
    test('handles missing optional fields with defaults', () {
      final response = GatewayHealthResponse.fromJson({});
      expect(response.status, 'unknown');
      expect(response.version, '');
      expect(response.uptimeSeconds, 0);
      expect(response.agents, 0);
      expect(response.channels, isEmpty);
      expect(response.latencyMs, 0);
    });
  });
}
