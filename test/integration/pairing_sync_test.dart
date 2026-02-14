import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/gateway_client.dart';
import 'package:clawfree/src/core/health_poller.dart';
import 'package:clawfree/src/core/watch_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatchSyncService Integration', () {
    late AgentStore agentStore;
    late HealthPoller healthPoller;
    late WatchSyncService syncService;
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('art.dart.clawfree/watch'),
            (MethodCall methodCall) async {
              methodCalls.add(methodCall);
              return null;
            },
          );

      agentStore = AgentStore();
      healthPoller = HealthPoller(
        gatewayClient: GatewayClient(baseUrl: 'http://localhost'),
      );
      syncService = WatchSyncService(
        healthPoller: healthPoller,
        agentStore: agentStore,
      );
    });

    test('initial sync sends correct data', () {
      syncService.start();

      expect(methodCalls.length, 1);
      final data = methodCalls.first.arguments as Map;
      expect(data['activeAgentCount'], 0);
      expect(data['healthLevel'], 'nominal');
      expect(data['isListening'], false);
    });

    test('stop() prevents further syncs', () async {
      syncService.start();
      methodCalls.clear();

      syncService.stop();
      agentStore.addAgent({'name': 'Ghost Agent'});
      await Future.microtask(() {});

      expect(methodCalls, isEmpty);
    });

    test('debounce collapses rapid listener notifications', () async {
      syncService.start();
      methodCalls.clear();

      agentStore.addAgent({'name': 'Agent 1'});
      agentStore.addAgent({'name': 'Agent 2'});
      await Future.microtask(() {});

      expect(methodCalls.length, 1);
      final data = methodCalls.first.arguments as Map;
      expect(data['activeAgentCount'], 2);
    });
  });
}
