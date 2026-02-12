import 'package:clawfree/src/core/shared_preferences_agent_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesAgentStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts empty', () async {
      final store = await SharedPreferencesAgentStore.create();
      expect(store.agents, isEmpty);
      expect(store.count, 0);
    });

    test('addAgent stores and notifies', () async {
      final store = await SharedPreferencesAgentStore.create();
      var notified = false;
      store.addListener(() => notified = true);

      store.addAgent({'name': 'Bot1', 'model': 'opus'});
      expect(store.count, 1);
      expect(store.agents.first['name'], 'Bot1');
      expect(store.agents.first['created_at'], isNotNull);
      expect(store.agents.first['status'], 'active');
      expect(notified, true);
    });

    test('findByName returns agent or null', () async {
      final store = await SharedPreferencesAgentStore.create();
      store.addAgent({'name': 'Bot1', 'model': 'opus'});

      expect(store.findByName('Bot1'), isNotNull);
      expect(store.findByName('Bot1')!['model'], 'opus');
      expect(store.findByName('NonExistent'), isNull);
    });

    test('removeByName removes agent and notifies', () async {
      final store = await SharedPreferencesAgentStore.create();
      store.addAgent({'name': 'Bot1'});
      store.addAgent({'name': 'Bot2'});

      var notified = false;
      store.addListener(() => notified = true);

      expect(store.removeByName('Bot1'), true);
      expect(store.count, 1);
      expect(store.findByName('Bot1'), isNull);
      expect(notified, true);
    });

    test('removeByName returns false for missing agent', () async {
      final store = await SharedPreferencesAgentStore.create();
      expect(store.removeByName('Ghost'), false);
    });

    test('clear empties store and notifies', () async {
      final store = await SharedPreferencesAgentStore.create();
      store.addAgent({'name': 'Bot1'});
      store.addAgent({'name': 'Bot2'});

      var notified = false;
      store.addListener(() => notified = true);

      store.clear();
      expect(store.count, 0);
      expect(notified, true);
    });

    test('persists across instances', () async {
      final store1 = await SharedPreferencesAgentStore.create();
      store1.addAgent({'name': 'Persistent', 'model': 'opus'});

      // Create a new instance — should load from SharedPreferences.
      final store2 = await SharedPreferencesAgentStore.create();
      expect(store2.count, 1);
      expect(store2.agents.first['name'], 'Persistent');
    });

    test('skips corrupt JSON entries', () async {
      // Seed SharedPreferences with one valid and one corrupt entry.
      SharedPreferences.setMockInitialValues({
        'clawfree_agents': [
          '{"name":"Good","model":"opus"}',
          'not-valid-json{{{',
          '{"name":"Also Good","model":"sonnet"}',
        ],
      });

      final store = await SharedPreferencesAgentStore.create();
      expect(store.count, 2);
      expect(store.agents[0]['name'], 'Good');
      expect(store.agents[1]['name'], 'Also Good');
    });
  });
}
