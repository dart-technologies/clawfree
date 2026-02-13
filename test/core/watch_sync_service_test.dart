import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/gateway_client.dart';
import 'package:clawfree/src/core/health_poller.dart';
import 'package:clawfree/src/core/watch_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('WatchSyncService unit', () {
    test('start() sends immediate sync with nominal defaults', () {
      syncService.start();

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'syncWatch');
      final data = methodCalls.first.arguments as Map;
      expect(data['activeAgentCount'], 0);
      expect(data['healthLevel'], 'nominal');
      expect(data['isListening'], false);
    });

    test('start() registers as listener on healthPoller and agentStore', () async {
      syncService.start();
      methodCalls.clear();

      // Mutating agent store should trigger sync
      agentStore.addAgent({'name': 'A'});
      await Future.microtask(() {});

      expect(methodCalls.length, 1);
      expect((methodCalls.first.arguments as Map)['activeAgentCount'], 1);
    });

    test('stop() deregisters listeners', () async {
      syncService.start();
      syncService.stop();
      methodCalls.clear();

      agentStore.addAgent({'name': 'Ghost'});
      await Future.microtask(() {});

      expect(methodCalls, isEmpty);
    });

    test('start-stop-start lifecycle works correctly', () async {
      syncService.start();
      syncService.stop();
      methodCalls.clear();

      // After stop, mutations should not trigger sync
      agentStore.addAgent({'name': 'Ignore'});
      await Future.microtask(() {});
      expect(methodCalls, isEmpty);

      // Restart
      syncService.start();
      expect(methodCalls.length, 1); // immediate sync from start()
      final data = methodCalls.first.arguments as Map;
      expect(data['activeAgentCount'], 1); // agent from above is still there
    });

    test('updateListening(true) triggers sync with isListening=true', () async {
      syncService.start();
      methodCalls.clear();

      syncService.updateListening(true);
      await Future.microtask(() {});

      expect(methodCalls.length, 1);
      expect((methodCalls.first.arguments as Map)['isListening'], true);
    });

    test('updateListening with same value is deduplicated', () async {
      syncService.start();
      methodCalls.clear();

      syncService.updateListening(false); // same as default
      await Future.microtask(() {});

      expect(methodCalls, isEmpty);
    });

    test('updateListening toggle cycle', () async {
      syncService.start();
      methodCalls.clear();

      syncService.updateListening(true);
      await Future.microtask(() {});
      expect(methodCalls.length, 1);
      expect((methodCalls.first.arguments as Map)['isListening'], true);

      methodCalls.clear();
      syncService.updateListening(false);
      await Future.microtask(() {});
      expect(methodCalls.length, 1);
      expect((methodCalls.first.arguments as Map)['isListening'], false);
    });

    test('debounce collapses multiple listener notifications', () async {
      syncService.start();
      methodCalls.clear();

      // Rapid-fire 3 agent additions in the same frame
      agentStore.addAgent({'name': 'A1'});
      agentStore.addAgent({'name': 'A2'});
      agentStore.addAgent({'name': 'A3'});
      await Future.microtask(() {});

      // Should collapse into one sync
      expect(methodCalls.length, 1);
      final data = methodCalls.first.arguments as Map;
      expect(data['activeAgentCount'], 3);
    });

    test('default health maps to nominal', () {
      syncService.start();
      expect((methodCalls.first.arguments as Map)['healthLevel'], 'nominal');
    });

    test('sync data includes all required fields', () {
      syncService.start();

      final data = methodCalls.first.arguments as Map;
      expect(data.containsKey('activeAgentCount'), isTrue);
      expect(data.containsKey('healthLevel'), isTrue);
      expect(data.containsKey('isListening'), isTrue);
      expect(data.containsKey('isPhoneActive'), isTrue);
      expect(data.length, 4);
    });

    test('agent count reflects current store state', () async {
      agentStore.addAgent({'name': 'Pre-existing'});
      syncService.start();

      expect((methodCalls.first.arguments as Map)['activeAgentCount'], 1);

      methodCalls.clear();
      agentStore.addAgent({'name': 'Second'});
      await Future.microtask(() {});
      expect((methodCalls.first.arguments as Map)['activeAgentCount'], 2);

      methodCalls.clear();
      agentStore.removeByName('Pre-existing');
      await Future.microtask(() {});
      expect((methodCalls.first.arguments as Map)['activeAgentCount'], 1);
    });

    test('channel errors are silently caught', () {
      // Replace mock with one that throws
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('art.dart.clawfree/watch'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'UNAVAILABLE', message: 'No watch');
        },
      );

      // Should not throw
      expect(() => syncService.start(), returnsNormally);
    });
  });
}
