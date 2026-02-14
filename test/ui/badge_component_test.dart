import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/badge_component.dart';
import 'package:clawfree/src/ui/chat/icon_resolver.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-badge';
}

void main() {
  group('Badge component', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: badgeCatalogBuilder(
              _MockContext({'text': 'Active'}),
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders with success variant color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: badgeCatalogBuilder(
              _MockContext({'text': 'OK', 'variant': 'success'}),
            ),
          ),
        ),
      );

      expect(find.text('OK'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, ClawfreeBorderRadius.pill);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: badgeCatalogBuilder(
              _MockContext({'text': 'Done', 'icon': 'check'}),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('defaults to neutral when no variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: badgeCatalogBuilder(
              _MockContext({'text': 'Default'}),
            ),
          ),
        ),
      );

      expect(find.text('Default'), findsOneWidget);
    });
  });

  group('icon_resolver', () {
    test('resolveIcon returns correct IconData', () {
      expect(resolveIcon('check'), Icons.check);
      expect(resolveIcon('warning'), Icons.warning_amber_rounded);
      expect(resolveIcon('send'), Icons.send);
    });

    test('resolveIcon returns null for unknown', () {
      expect(resolveIcon('nonexistent'), isNull);
      expect(resolveIcon(null), isNull);
    });

    test('parseHexColor parses valid hex', () {
      final color = parseHexColor('#FF6600');
      expect(color, isNotNull);
      expect(color, const Color(0xFFFF6600));
    });

    test('parseHexColor returns null for invalid', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor('not-a-color'), isNull);
    });
  });
}
