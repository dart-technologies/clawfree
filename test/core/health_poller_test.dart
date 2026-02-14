import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:clawfree/src/core/gateway_client.dart';
import 'package:clawfree/src/core/health_poller.dart';
import 'package:clawfree/src/core/platform_config.dart';
import 'package:clawfree/src/core/remote_session.dart';
import 'package:clawfree/src/ui/health/health_state.dart';

http.Response _healthResponse({
  String status = 'ok',
  String version = '1.4.2',
  int uptimeSeconds = 3600,
  int agents = 2,
  Map<String, String> channels = const {'telegram': 'active'},
  int latencyMs = 45,
}) {
  return http.Response(
    jsonEncode({
      'status': status,
      'version': version,
      'uptime_seconds': uptimeSeconds,
      'agents': agents,
      'channels': channels,
      'latency_ms': latencyMs,
    }),
    200,
  );
}

void main() {
  group('HealthPoller', () {
    test('start triggers immediate poll and updates state', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => _healthResponse(),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(
        gatewayClient: gateway,
        interval: const Duration(seconds: 60),
      );

      // Before start, state is optimistic nominal
      expect(poller.state.overall, HealthLevel.nominal);

      poller.start();
      // Let the async poll complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(poller.state.overall, HealthLevel.nominal);
      expect(poller.state.gateway.level, HealthLevel.nominal);
      expect(poller.state.gateway.detail, '45ms');

      poller.dispose();
      gateway.dispose();
    });

    test('pollOnce updates state without starting timer', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => _healthResponse(latencyMs: 12),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      await poller.pollOnce();

      expect(poller.state.gateway.detail, '12ms');
      expect(poller.state.overall, HealthLevel.nominal);

      poller.dispose();
      gateway.dispose();
    });

    test('error sets gateway to error after 3 consecutive failures', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => http.Response('Server Error', 500),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      // First two failures keep nominal (optimistic)
      await poller.pollOnce();
      expect(poller.state.overall, HealthLevel.nominal);
      await poller.pollOnce();
      expect(poller.state.overall, HealthLevel.nominal);

      // Third failure triggers error
      await poller.pollOnce();
      expect(poller.state.gateway.level, HealthLevel.error);
      expect(poller.state.gateway.detail, 'Unreachable');
      expect(poller.state.overall, HealthLevel.error);

      poller.dispose();
      gateway.dispose();
    });

    test('maps degraded status correctly', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => _healthResponse(status: 'degraded'),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      await poller.pollOnce();

      expect(poller.state.gateway.level, HealthLevel.degraded);

      poller.dispose();
      gateway.dispose();
    });

    test('maps channels: partial active = degraded', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => _healthResponse(
          channels: {'telegram': 'active', 'slack': 'disconnected'},
        ),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      await poller.pollOnce();

      expect(poller.state.channels.level, HealthLevel.degraded);
      expect(poller.state.channels.detail, '1/2 active');

      poller.dispose();
      gateway.dispose();
    });

    test('maps channels: all disconnected = error', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => _healthResponse(
          channels: {'telegram': 'disconnected', 'slack': 'disconnected'},
        ),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      await poller.pollOnce();

      expect(poller.state.channels.level, HealthLevel.error);
      expect(poller.state.channels.detail, '0/2 active');

      poller.dispose();
      gateway.dispose();
    });

    test('stop cancels timer — no further polls after stop', () async {
      int requestCount = 0;
      final mockHttp = http_testing.MockClient((request) async {
        requestCount++;
        return _healthResponse();
      });
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(
        gatewayClient: gateway,
        interval: const Duration(milliseconds: 50),
      );

      poller.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final countAfterStart = requestCount;

      poller.stop();
      // Wait well past the interval
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // No more requests should have been made after stop
      expect(requestCount, countAfterStart);

      poller.dispose();
      gateway.dispose();
    });

    test('dispose stops timer', () async {
      int requestCount = 0;
      final mockHttp = http_testing.MockClient((request) async {
        requestCount++;
        return _healthResponse();
      });
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(
        gatewayClient: gateway,
        interval: const Duration(milliseconds: 50),
      );

      poller.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final countAfterStart = requestCount;

      poller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // No more requests after dispose
      expect(requestCount, countAfterStart);

      gateway.dispose();
    });

    test('notifies listeners on each poll', () async {
      final mockHttp = http_testing.MockClient(
        (request) async => _healthResponse(),
      );
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      int notifyCount = 0;
      poller.addListener(() => notifyCount++);

      await poller.pollOnce();
      // GatewayClient also notifies, but HealthPoller should notify once per poll
      expect(notifyCount, 1);

      await poller.pollOnce();
      expect(notifyCount, 2);

      poller.dispose();
      gateway.dispose();
    });

    test(
      'sessions empty by default when gateway returns health JSON for /sessions',
      () async {
        // Mock returns health-shaped JSON for all paths, which is not a valid
        // sessions response — sessions should default to empty.
        final mockHttp = http_testing.MockClient(
          (request) async => _healthResponse(),
        );
        final gateway = GatewayClient(
          baseUrl: 'http://localhost:18789',
          httpClient: mockHttp,
        );
        final poller = HealthPoller(gatewayClient: gateway);

        await poller.pollOnce();

        expect(poller.sessions, isEmpty);

        poller.dispose();
        gateway.dispose();
      },
    );

    test('parses sessions from gateway', () async {
      final mockHttp = http_testing.MockClient((request) async {
        if (request.url.path == '/sessions') {
          return http.Response(
            jsonEncode([
              {
                'session_id': 's1',
                'device_type': 'phone',
                'device_name': "Mike's iPhone",
              },
              {
                'session_id': 's2',
                'device_type': 'watch',
                'device_name': "Mike's Watch",
              },
            ]),
            200,
          );
        }
        return _healthResponse();
      });
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(gatewayClient: gateway);

      await poller.pollOnce();

      expect(poller.sessions, hasLength(2));
      expect(poller.sessions[0].deviceName, "Mike's iPhone");
      expect(poller.sessions[0].deviceType, DeviceFormFactor.phone);
      expect(poller.sessions[1].deviceName, "Mike's Watch");
      expect(poller.sessions[1].deviceType, DeviceFormFactor.watch);

      poller.dispose();
      gateway.dispose();
    });

    test('filters out self session by selfSessionId', () async {
      final mockHttp = http_testing.MockClient((request) async {
        if (request.url.path == '/sessions') {
          return http.Response(
            jsonEncode([
              {
                'session_id': 'self-id',
                'device_type': 'tablet',
                'device_name': 'My iPad',
              },
              {
                'session_id': 'other-id',
                'device_type': 'phone',
                'device_name': "Mike's iPhone",
              },
            ]),
            200,
          );
        }
        return _healthResponse();
      });
      final gateway = GatewayClient(
        baseUrl: 'http://localhost:18789',
        httpClient: mockHttp,
      );
      final poller = HealthPoller(
        gatewayClient: gateway,
        selfSessionId: 'self-id',
      );

      await poller.pollOnce();

      expect(poller.sessions, hasLength(1));
      expect(poller.sessions[0].sessionId, 'other-id');

      poller.dispose();
      gateway.dispose();
    });

    test(
      'falls back to demoSessions after 3 consecutive session errors',
      () async {
        final mockHttp = http_testing.MockClient((request) async {
          if (request.url.path == '/sessions') {
            return http.Response('Not Found', 404);
          }
          return _healthResponse();
        });
        final gateway = GatewayClient(
          baseUrl: 'http://localhost:18789',
          httpClient: mockHttp,
        );
        final demoSessions = [
          const RemoteSession(
            sessionId: 'demo-1',
            deviceType: DeviceFormFactor.phone,
            deviceName: 'Demo Phone',
          ),
        ];
        final poller = HealthPoller(
          gatewayClient: gateway,
          demoSessions: demoSessions,
        );

        // First two failures: sessions remain empty
        await poller.pollOnce();
        expect(poller.sessions, isEmpty);
        await poller.pollOnce();
        expect(poller.sessions, isEmpty);

        // Third failure: fall back to demoSessions
        await poller.pollOnce();
        expect(poller.sessions, hasLength(1));
        expect(poller.sessions[0].deviceName, 'Demo Phone');

        poller.dispose();
        gateway.dispose();
      },
    );
  });
}
