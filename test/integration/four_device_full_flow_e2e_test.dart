// Full 4-device demo scenario E2E tests.
//
// Uses real LocalSyncServer and LocalSyncClient to verify broadcast
// of AI responses from iPhone host to iPad and macOS clients.

@TestOn('vm')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/services/local_sync_server.dart';
import 'package:clawfree/src/services/local_sync_client.dart';

/// Simulate iPhone host: run AI, broadcast user msg + response.
Future<String> simulateHost(
  LocalSyncServer server,
  DemoCacheAiClient ai,
  String text,
) async {
  server.broadcastUserMessage(text, source: 'watch');
  final buf = StringBuffer();
  await for (final c in ai.sendStream(text, systemPrompt: '', history: [])) {
    buf.write(c);
  }
  final response = buf.toString();
  final match = RegExp(r'"surfaceId"\s*:\s*"([^"]+)"').firstMatch(response);
  server.broadcastAiResponse(response, a2ui: match?.group(1));
  return response;
}

void main() {
  late LocalSyncServer server;
  late LocalSyncClient ipadClient;
  late LocalSyncClient macClient;
  late DemoCacheAiClient aiClient;

  const port = 18799;

  setUp(() async {
    server = LocalSyncServer(port: port);
    await server.start();
    ipadClient = LocalSyncClient(serverUrl: 'ws://127.0.0.1:$port');
    macClient = LocalSyncClient(serverUrl: 'ws://127.0.0.1:$port');
    await ipadClient.connect();
    await macClient.connect();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(server.clientCount, 2);
    aiClient = DemoCacheAiClient(chunkDelay: Duration.zero);
  });

  tearDown(() async {
    aiClient.dispose();
    await ipadClient.disconnect();
    await macClient.disconnect();
    await server.stop();
  });

  group('4-device: connectivity', () {
    test('server accepts 2 clients', () {
      expect(server.isRunning, isTrue);
      expect(server.clientCount, 2);
      expect(ipadClient.isConnected, isTrue);
      expect(macClient.isConnected, isTrue);
    });

    test('broadcast user message reaches both clients', () async {
      final ipad = <SyncEvent>[], mac = <SyncEvent>[];
      final s1 = ipadClient.events.listen(ipad.add);
      final s2 = macClient.events.listen(mac.add);

      server.broadcastUserMessage('Hello from Watch', source: 'watch');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(ipad.length, 1);
      expect(ipad.first.type, 'user_message');
      expect(ipad.first.text, 'Hello from Watch');
      expect(mac.length, 1);

      await s1.cancel();
      await s2.cancel();
    });

    test('broadcast AI response with a2ui reaches both', () async {
      final ipad = <SyncEvent>[], mac = <SyncEvent>[];
      final s1 = ipadClient.events.listen(ipad.add);
      final s2 = macClient.events.listen(mac.add);

      server.broadcastAiResponse('Ready!', a2ui: 'test-001');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(ipad.first.a2ui, 'test-001');
      expect(mac.first.a2ui, 'test-001');

      await s1.cancel();
      await s2.cancel();
    });
  });

  group('4-device: Watch → iPhone AI → broadcast', () {
    test('"create agent" broadcasts to both clients', () async {
      final ipad = <SyncEvent>[];
      final s1 = ipadClient.events.listen(ipad.add);

      await simulateHost(server, aiClient, 'create agent');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(ipad.length, 2); // user_message + ai_response
      expect(ipad.first.type, 'user_message');
      expect(ipad.last.type, 'ai_response');
      expect(ipad.last.a2ui, 'agent-form-001');

      await s1.cancel();
    });

    test('"plan a 3 day visit" broadcasts itinerary', () async {
      final ipad = <SyncEvent>[];
      final s1 = ipadClient.events.listen(ipad.add);

      await simulateHost(server, aiClient, 'plan a 3 day visit');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final ai = ipad.firstWhere((e) => e.type == 'ai_response');
      expect(ai.a2ui, 'trip-itin-001');

      await s1.cancel();
    });

    test('"sushi class" broadcasts modification', () async {
      final mac = <SyncEvent>[];
      final s1 = macClient.events.listen(mac.add);

      await simulateHost(server, aiClient, 'I want a sushi class');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final ai = mac.firstWhere((e) => e.type == 'ai_response');
      expect(ai.text.toLowerCase(), contains('sushi'));

      await s1.cancel();
    });
  });

  group('4-device: surface ID consistency', () {
    test('same surface ID on both devices', () async {
      final ipad = <SyncEvent>[], mac = <SyncEvent>[];
      final s1 = ipadClient.events.listen(ipad.add);
      final s2 = macClient.events.listen(mac.add);

      await simulateHost(server, aiClient, 'plan a 3 day visit');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final iSurf = ipad.firstWhere((e) => e.type == 'ai_response').a2ui;
      final mSurf = mac.firstWhere((e) => e.type == 'ai_response').a2ui;
      expect(iSurf, equals(mSurf));
      expect(iSurf, 'trip-itin-001');

      await s1.cancel();
      await s2.cancel();
    });
  });

  group('4-device: disconnect/reconnect', () {
    test('remaining client still receives after one disconnects', () async {
      await ipadClient.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(server.clientCount, 1);

      final mac = <SyncEvent>[];
      final s1 = macClient.events.listen(mac.add);

      server.broadcastAiResponse('Still working!');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(mac.length, 1);
      expect(mac.first.text, 'Still working!');

      await s1.cancel();
    });

    test('new client receives subsequent messages', () async {
      await ipadClient.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final newClient = LocalSyncClient(serverUrl: 'ws://127.0.0.1:$port');
      await newClient.connect();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(server.clientCount, 2);

      final events = <SyncEvent>[];
      final s = newClient.events.listen(events.add);

      server.broadcastAiResponse('Welcome back!');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(events.length, 1);
      expect(events.first.text, 'Welcome back!');

      await s.cancel();
      await newClient.disconnect();
    });
  });

  group('4-device: full demo scenario', () {
    test('complete 3-step Watch→iPhone→all devices flow', () async {
      final ipad = <SyncEvent>[], mac = <SyncEvent>[];
      final s1 = ipadClient.events.listen(ipad.add);
      final s2 = macClient.events.listen(mac.add);

      await simulateHost(server, aiClient, 'create agent');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await simulateHost(server, aiClient, 'plan a 3 day visit');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await simulateHost(server, aiClient, 'I want a sushi class');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 3 steps × 2 events = 6
      expect(ipad.length, 6);
      expect(mac.length, 6);

      // User messages in order
      final userTexts = ipad
          .where((e) => e.type == 'user_message')
          .map((e) => e.text)
          .toList();
      expect(userTexts, [
        'create agent',
        'plan a 3 day visit',
        'I want a sushi class',
      ]);

      // AI surface IDs
      final surfaces = ipad
          .where((e) => e.type == 'ai_response')
          .map((e) => e.a2ui)
          .toList();
      expect(surfaces[0], 'agent-form-001');
      expect(surfaces[1], 'trip-itin-001');
      expect(surfaces[2], 'trip-itin-001'); // updateComponents

      await s1.cancel();
      await s2.cancel();
    });
  });
}
