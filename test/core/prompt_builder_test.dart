import 'package:clawfree/src/core/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptBuilder', () {
    test('section adds named header', () {
      final result = PromptBuilder()
          .section('My Section', 'Section content.')
          .build();

      expect(result, contains('# My Section'));
      expect(result, contains('Section content.'));
    });

    test('raw adds content without header', () {
      final result = PromptBuilder().raw('Just text.').build();

      expect(result, equals('Just text.'));
      expect(result, isNot(contains('#')));
    });

    test('schema wraps content in a2ui_schema tags', () {
      final result = PromptBuilder().schema('{"components": []}').build();

      expect(result, contains('<a2ui_schema>'));
      expect(result, contains('{"components": []}'));
      expect(result, contains('</a2ui_schema>'));
    });

    test('rules adds content when non-empty', () {
      final result = PromptBuilder().rules('Some rules here.').build();

      expect(result, contains('Some rules here.'));
    });

    test('rules is no-op when empty', () {
      final result = PromptBuilder().raw('Start').rules('').raw('End').build();

      expect(result, isNot(contains('\n\n\n\n')));
    });

    test('agentContext adds agent list when non-empty', () {
      final agents = [
        {
          'name': 'Bot1',
          'model': 'opus',
          'tools': ['Browser'],
        },
        {'name': 'Bot2', 'model': 'sonnet', 'tools': <String>[]},
      ];
      final result = PromptBuilder().agentContext(agents).build();

      expect(result, contains('# Saved Agents'));
      expect(result, contains('Bot1'));
      expect(result, contains('Bot2'));
      expect(result, contains('Browser'));
    });

    test('agentContext is no-op on empty list', () {
      final result = PromptBuilder().raw('Start').agentContext([]).build();

      expect(result, equals('Start'));
    });

    test('activeSurfaces adds surface list when non-empty', () {
      final result = PromptBuilder().activeSurfaces([
        'surface-001',
        'surface-002',
      ]).build();

      expect(result, contains('# Active Surfaces'));
      expect(result, contains('- surface-001'));
      expect(result, contains('- surface-002'));
    });

    test('activeSurfaces is no-op on empty list', () {
      final result = PromptBuilder().raw('Start').activeSurfaces([]).build();

      expect(result, equals('Start'));
    });

    test('fluent chaining produces combined output', () {
      final result = PromptBuilder()
          .raw('Intro text.')
          .section('Rules', 'Do this.')
          .schema('{}')
          .raw('Footer.')
          .build();

      expect(result, contains('Intro text.'));
      expect(result, contains('# Rules'));
      expect(result, contains('<a2ui_schema>'));
      expect(result, contains('Footer.'));
    });

    test('sections are separated by double newlines', () {
      final result = PromptBuilder().raw('First').raw('Second').build();

      expect(result, contains('First\n\nSecond'));
    });
  });
}
