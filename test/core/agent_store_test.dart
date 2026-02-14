import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';

void main() {
  group('AgentStore', () {
    late AgentStore store;

    setUp(() {
      store = AgentStore();
    });

    test('starts empty', () {
      expect(store.agents, isEmpty);
      expect(store.count, 0);
    });

    test('addAgent increases count', () {
      store.addAgent({'name': 'TestBot'});
      expect(store.count, 1);
      expect(store.agents.first['name'], 'TestBot');
    });

    test('addAgent sets default created_at and status', () {
      store.addAgent({'name': 'TestBot'});
      final agent = store.agents.first;
      expect(agent['created_at'], isNotNull);
      expect(agent['status'], 'active');
    });

    test('addAgent preserves existing created_at', () {
      store.addAgent({'name': 'TestBot', 'created_at': '2026-01-01T00:00:00'});
      expect(store.agents.first['created_at'], '2026-01-01T00:00:00');
    });

    test('addAgent creates a defensive copy', () {
      final config = {'name': 'TestBot'};
      store.addAgent(config);
      config['name'] = 'Modified';
      expect(store.agents.first['name'], 'TestBot');
    });

    test('findByName returns matching agent', () {
      store.addAgent({'name': 'Alpha'});
      store.addAgent({'name': 'Beta'});
      final found = store.findByName('Beta');
      expect(found, isNotNull);
      expect(found!['name'], 'Beta');
    });

    test('findByName returns null for missing agent', () {
      store.addAgent({'name': 'Alpha'});
      expect(store.findByName('Missing'), isNull);
    });

    test('removeByName removes existing agent', () {
      store.addAgent({'name': 'Alpha'});
      store.addAgent({'name': 'Beta'});
      final result = store.removeByName('Alpha');
      expect(result, isTrue);
      expect(store.count, 1);
      expect(store.agents.first['name'], 'Beta');
    });

    test('removeByName returns false for missing agent', () {
      store.addAgent({'name': 'Alpha'});
      final result = store.removeByName('Missing');
      expect(result, isFalse);
      expect(store.count, 1);
    });

    test('agents list is unmodifiable', () {
      store.addAgent({'name': 'Test'});
      expect(() => store.agents.add({'name': 'Hack'}), throwsUnsupportedError);
    });

    test('notifies listeners on addAgent', () {
      var notified = false;
      store.addListener(() => notified = true);
      store.addAgent({'name': 'Test'});
      expect(notified, isTrue);
    });

    test('notifies listeners on removeByName', () {
      store.addAgent({'name': 'Test'});
      var notified = false;
      store.addListener(() => notified = true);
      store.removeByName('Test');
      expect(notified, isTrue);
    });

    test('multiple agents stored independently', () {
      store.addAgent({'name': 'A', 'model': 'opus'});
      store.addAgent({'name': 'B', 'model': 'sonnet'});
      store.addAgent({'name': 'C', 'model': 'gpt'});
      expect(store.count, 3);
      expect(store.findByName('B')!['model'], 'sonnet');
    });
  });
}
