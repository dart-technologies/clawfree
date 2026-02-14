import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/services/local_sync_server.dart';
import 'package:clawfree/src/services/local_sync_client.dart';

/// E2E Test: 四設備同步測試
/// 
/// 測試場景：
/// 1. iPhone (host) 發訊息 → iPad/macOS (clients) 收到
/// 2. iPad/macOS 發訊息 → iPhone 收到並轉發
/// 3. Watch → iPhone → broadcast to iPad/macOS
/// 4. 選項變更同步（surface state sync）
void main() {
  group('Four-Device Sync E2E', () {
    late LocalSyncServer server;
    late LocalSyncClient client1; // iPad
    late LocalSyncClient client2; // macOS

    setUp(() async {
      // Setup: iPhone acts as host/server (use unique port for testing)
      server = LocalSyncServer(port: 18765);
      await server.start();

      // Setup: iPad and macOS as clients
      client1 = LocalSyncClient(serverUrl: 'ws://localhost:${server.port}');
      await client1.connect();

      client2 = LocalSyncClient(serverUrl: 'ws://localhost:${server.port}');
      await client2.connect();

      // Wait for connections to stabilize
      await Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown(() async {
      await client1.disconnect();
      await client2.disconnect();
      await server.stop();
    });

    test('1. iPhone (host) sends message → iPad/macOS receive', () async {
      final completer1 = Completer<SyncEvent>();
      final completer2 = Completer<SyncEvent>();

      // iPad listens
      final sub1 = client1.events.listen((event) {
        if (event.type == 'user_message' && !completer1.isCompleted) {
          completer1.complete(event);
        }
      });

      // macOS listens
      final sub2 = client2.events.listen((event) {
        if (event.type == 'user_message' && !completer2.isCompleted) {
          completer2.complete(event);
        }
      });

      // iPhone sends
      const testMessage = 'Hello from iPhone';
      server.broadcastUserMessage(testMessage, source: 'keyboard');

      // Wait for both clients to receive
      final event1 = await completer1.future.timeout(const Duration(seconds: 2));
      final event2 = await completer2.future.timeout(const Duration(seconds: 2));

      expect(event1.data['text'], equals(testMessage));
      expect(event1.data['source'], equals('keyboard'));
      expect(event2.data['text'], equals(testMessage));
      expect(event2.data['source'], equals('keyboard'));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('2. iPad sends message → iPhone receives and forwards', () async {
      final completerHost = Completer<Map<String, dynamic>>();
      final completerMac = Completer<SyncEvent>();

      // iPhone (server) listens
      final subHost = server.incomingMessages.listen((data) {
        if (data['type'] == 'user_message' && !completerHost.isCompleted) {
          completerHost.complete(data);
        }
      });

      // macOS listens (should receive forwarded message)
      final subMac = client2.events.listen((event) {
        if (event.type == 'user_message' && !completerMac.isCompleted) {
          completerMac.complete(event);
        }
      });

      // iPad sends
      const testMessage = 'Hello from iPad';
      client1.sendUserMessage(testMessage, source: 'voice');

      // Wait for iPhone to receive
      final eventHost = await completerHost.future.timeout(const Duration(seconds: 2));
      expect(eventHost['text'], equals(testMessage));
      expect(eventHost['source'], equals('voice'));

      // iPhone should forward to macOS
      server.broadcastUserMessage(testMessage, source: 'voice');

      // Wait for macOS to receive
      final eventMac = await completerMac.future.timeout(const Duration(seconds: 2));
      expect(eventMac.data['text'], equals(testMessage));

      await subHost.cancel();
      await subMac.cancel();
    });

    test('3. Watch → iPhone → iPad/macOS', () async {
      final completer1 = Completer<SyncEvent>();
      final completer2 = Completer<SyncEvent>();

      // iPad listens
      final sub1 = client1.events.listen((event) {
        if (event.type == 'user_message' && !completer1.isCompleted) {
          completer1.complete(event);
        }
      });

      // macOS listens
      final sub2 = client2.events.listen((event) {
        if (event.type == 'user_message' && !completer2.isCompleted) {
          completer2.complete(event);
        }
      });

      // Simulate Watch → iPhone flow
      const watchMessage = 'Plan a 3 day trip to Tokyo';
      server.broadcastUserMessage(watchMessage, source: 'watch');

      // Both clients should receive
      final event1 = await completer1.future.timeout(const Duration(seconds: 2));
      final event2 = await completer2.future.timeout(const Duration(seconds: 2));

      expect(event1.data['text'], equals(watchMessage));
      expect(event1.data['source'], equals('watch'));
      expect(event2.data['text'], equals(watchMessage));
      expect(event2.data['source'], equals('watch'));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('4. Surface state sync (Watch UI state)', () async {
      final completer1 = Completer<Map<String, dynamic>>();
      final completer2 = Completer<Map<String, dynamic>>();

      // iPad listens for UI state
      final sub1 = client1.events.listen((event) {
        if (event.type == 'raw' && !completer1.isCompleted) {
          completer1.complete(event.data);
        }
      });

      // macOS listens for UI state
      final sub2 = client2.events.listen((event) {
        if (event.type == 'raw' && !completer2.isCompleted) {
          completer2.complete(event.data);
        }
      });

      // Simulate Watch UI state change (e.g., AgentConfig step change)
      final uiState = {
        'flow': 'agentConfig',
        'step': 1,
        'selectedModel': 'Opus 4.6',
        'selectedModelEmoji': '🧠',
        'selectedSkills': ['Flight Search', 'Hotel Booking'],
      };

      server.broadcastRaw(uiState);

      // Both clients should receive the same state
      final state1 = await completer1.future.timeout(const Duration(seconds: 2));
      final state2 = await completer2.future.timeout(const Duration(seconds: 2));

      expect(state1['flow'], equals('agentConfig'));
      expect(state1['step'], equals(1));
      expect(state1['selectedModel'], equals('Opus 4.6'));
      expect(state1['selectedSkills'], isA<List>());
      expect((state1['selectedSkills'] as List).length, equals(2));

      expect(state2['flow'], equals('agentConfig'));
      expect(state2['step'], equals(1));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('5. Multiple rapid messages maintain order', () async {
      final received1 = <String>[];
      final received2 = <String>[];

      // iPad listens
      final sub1 = client1.events.listen((event) {
        if (event.type == 'user_message') {
          received1.add(event.data['text'] as String);
        }
      });

      // macOS listens
      final sub2 = client2.events.listen((event) {
        if (event.type == 'user_message') {
          received2.add(event.data['text'] as String);
        }
      });

      // Send multiple messages rapidly
      final messages = ['msg1', 'msg2', 'msg3', 'msg4', 'msg5'];
      for (final msg in messages) {
        server.broadcastUserMessage(msg, source: 'test');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Wait for all messages to arrive
      await Future.delayed(const Duration(seconds: 1));

      // Both clients should receive all messages in order
      expect(received1.length, equals(5));
      expect(received2.length, equals(5));
      expect(received1, equals(messages));
      expect(received2, equals(messages));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('6. Client reconnection after disconnect', () async {
      // Disconnect iPad
      await client1.disconnect();
      await Future.delayed(const Duration(milliseconds: 200));

      // Reconnect iPad
      await client1.connect();
      await Future.delayed(const Duration(milliseconds: 500));

      final completer = Completer<SyncEvent>();

      // iPad listens after reconnection
      final sub = client1.events.listen((event) {
        if (event.type == 'user_message' && !completer.isCompleted) {
          completer.complete(event);
        }
      });

      // iPhone sends
      const testMessage = 'Message after reconnect';
      server.broadcastUserMessage(testMessage, source: 'test');

      // iPad should still receive
      final event = await completer.future.timeout(const Duration(seconds: 2));
      expect(event.data['text'], equals(testMessage));

      await sub.cancel();
    });
  });
}
