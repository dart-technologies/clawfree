import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_config_parser.dart';

void main() {
  group('AgentConfigParser', () {
    test('tryParse returns config for valid agent data', () {
      final data = jsonEncode({
        '/agent/name': 'TestBot',
        '/agent/model': 'claude-opus-4-6',
        '/agent/tools': ['browser', 'search'],
        '/agent/channels': ['telegram'],
      });
      final config = AgentConfigParser.tryParse(data);
      expect(config, isNotNull);
      final cfg = config as Map<String, dynamic>;
      expect(cfg['name'], 'TestBot');
      expect(cfg['model'], 'claude-opus-4-6');
      expect(cfg['tools'], ['browser', 'search']);
      expect(cfg['channels'], ['telegram']);
      expect((cfg['config'] as Map)['version'], '1.0');
      expect((cfg['config'] as Map)['created_by'], 'clawfree');
    });

    test('tryParse returns null for non-agent data', () {
      final data = jsonEncode({'key': 'value', 'other': 42});
      expect(AgentConfigParser.tryParse(data), isNull);
    });

    test('tryParse returns null for invalid JSON', () {
      expect(AgentConfigParser.tryParse('not json'), isNull);
    });

    test('tryParse returns null for non-map JSON', () {
      expect(AgentConfigParser.tryParse('[1, 2, 3]'), isNull);
    });

    test('tryParse fills defaults for missing fields', () {
      final data = jsonEncode({'/agent/name': 'MyBot'});
      final config = AgentConfigParser.tryParse(data)!;
      expect(config['name'], 'MyBot');
      expect(config['model'], 'claude-opus-4-6');
      expect(config['tools'], []);
      expect(config['channels'], []);
    });

    test('parse throws on invalid JSON', () {
      expect(
        () => AgentConfigParser.parse('not json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromHistory finds agent config in chat history', () {
      final history = <Map<String, String>>[
        {'role': 'user', 'content': 'Create an agent'},
        {'role': 'assistant', 'content': 'Sure!'},
        {
          'role': 'user',
          'content': jsonEncode({
            'path': '/submit',
            '/agent/name': 'HistoryBot',
            '/agent/model': 'gpt-4o',
          }),
        },
      ];
      final config = AgentConfigParser.fromHistory(history);
      expect(config, isNotNull);
      expect(config!['name'], 'HistoryBot');
      expect(config['model'], 'gpt-4o');
    });

    test('fromHistory returns null when no agent config found', () {
      final history = <Map<String, String>>[
        {'role': 'user', 'content': 'Hello'},
        {'role': 'assistant', 'content': 'Hi there'},
      ];
      expect(AgentConfigParser.fromHistory(history), isNull);
    });

    test('fromHistory picks most recent agent config', () {
      final history = <Map<String, String>>[
        {
          'role': 'user',
          'content': jsonEncode({'path': '/submit', '/agent/name': 'OldBot'}),
        },
        {'role': 'assistant', 'content': 'Saved!'},
        {
          'role': 'user',
          'content': jsonEncode({'path': '/submit', '/agent/name': 'NewBot'}),
        },
      ];
      final config = AgentConfigParser.fromHistory(history);
      expect(config!['name'], 'NewBot');
    });
  });
}
