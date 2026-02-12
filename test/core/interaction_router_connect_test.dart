import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/gateway_client.dart';
import 'package:clawfree/src/core/interaction_router.dart';
import 'package:clawfree/src/core/prompt_library.dart';

ChatMessage _actionMessage(String actionName, Map<String, dynamic> context) {
  final json = jsonEncode({
    'action': {'name': actionName, 'context': context},
  });
  return ChatMessage(role: ChatMessageRole.user, parts: [TextPart(json)]);
}

void main() {
  group('connect_gateway action', () {
    test('with url and token returns ModeSwitchResult to home', () {
      final mockHttp = http_testing.MockClient(
        (request) async => http.Response('', 200),
      );
      final gatewayClient = GatewayClient(
        baseUrl: 'http://old:18789',
        httpClient: mockHttp,
      );
      final router = A2uiInteractionRouter(
        agentStore: AgentStore(),
        gatewayClient: gatewayClient,
      );

      final result = router.handle(_actionMessage('connect_gateway', {
        'gateway_url': 'http://new-host:18789',
        'gateway_token': 'my-secret-token',
      }));

      expect(result, isA<ModeSwitchResult>());
      final msr = result as ModeSwitchResult;
      expect(msr.targetMode, SessionMode.home);
      expect(msr.message.text, contains('Connected to gateway'));
      expect(gatewayClient.baseUrl, 'http://new-host:18789');

      gatewayClient.dispose();
    });

    test('missing url returns UserInputResult', () {
      final router = A2uiInteractionRouter(
        agentStore: AgentStore(),
      );

      final result = router.handle(_actionMessage('connect_gateway', {
        'gateway_url': '',
        'gateway_token': 'token',
      }));

      expect(result, isA<UserInputResult>());
      final uir = result as UserInputResult;
      expect(uir.text, contains('gateway URL'));
    });

    test('updates GatewayClient baseUrl and token', () {
      final mockHttp = http_testing.MockClient(
        (request) async => http.Response('', 200),
      );
      final gatewayClient = GatewayClient(
        baseUrl: 'http://initial:18789',
        token: '',
        httpClient: mockHttp,
      );
      final router = A2uiInteractionRouter(
        agentStore: AgentStore(),
        gatewayClient: gatewayClient,
      );

      router.handle(_actionMessage('connect_gateway', {
        'gateway_url': 'http://updated:18789',
        'gateway_token': 'new-token',
      }));

      expect(gatewayClient.baseUrl, 'http://updated:18789');
      // isConnected is false after updateBaseUrl (needs a health check to reconnect)
      expect(gatewayClient.isConnected, isFalse);

      gatewayClient.dispose();
    });

    test('works without GatewayClient (no crash)', () {
      final router = A2uiInteractionRouter(
        agentStore: AgentStore(),
        // no gatewayClient
      );

      final result = router.handle(_actionMessage('connect_gateway', {
        'gateway_url': 'http://some-host:18789',
      }));

      // Still returns ModeSwitchResult even without a GatewayClient instance
      expect(result, isA<ModeSwitchResult>());
    });

    test('token is optional — only url is required', () {
      final mockHttp = http_testing.MockClient(
        (request) async => http.Response('', 200),
      );
      final gatewayClient = GatewayClient(
        baseUrl: 'http://old:18789',
        httpClient: mockHttp,
      );
      final router = A2uiInteractionRouter(
        agentStore: AgentStore(),
        gatewayClient: gatewayClient,
      );

      final result = router.handle(_actionMessage('connect_gateway', {
        'gateway_url': 'http://no-token:18789',
        // no gateway_token
      }));

      expect(result, isA<ModeSwitchResult>());
      expect(gatewayClient.baseUrl, 'http://no-token:18789');

      gatewayClient.dispose();
    });
  });
}
