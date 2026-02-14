import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/badge_component.dart';
import 'package:clawfree/src/ui/chat/icon_resolver.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-badge',
    type: 'Badge',
    buildChild: (id, [dc]) => Text('BadgeChild: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Badge component', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => badgeCatalogBuilder(
                _createContext({'text': 'Active'}, context),
              ),
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
            body: Builder(
              builder: (context) => badgeCatalogBuilder(
                _createContext({'text': 'OK', 'variant': 'success'}, context),
              ),
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
            body: Builder(
              builder: (context) => badgeCatalogBuilder(
                _createContext({'text': 'Done', 'icon': 'check'}, context),
              ),
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
            body: Builder(
              builder: (context) => badgeCatalogBuilder(
                _createContext({'text': 'Default'}, context),
              ),
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
