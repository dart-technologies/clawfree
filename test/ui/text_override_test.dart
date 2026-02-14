import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/text_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockDataContext extends Fake implements DataContext {
  ValueNotifier<String?> subscribeToString(Object? value) {
    if (value is String) return ValueNotifier<String?>(value);
    return ValueNotifier<String?>(null);
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-text';
  @override
  DataContext get dataContext => _MockDataContext();
}

void main() {
  group('Text override', () {
    testWidgets('renders body variant with markdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'Hello world',
              'variant': 'body',
            })),
          ),
        ),
      );

      expect(find.textContaining('Hello world'), findsOneWidget);
    });

    testWidgets('renders technical variant uppercase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'status ok',
              'variant': 'technical',
            })),
          ),
        ),
      );

      expect(find.text('STATUS OK'), findsOneWidget);
    });

    testWidgets('renders label variant uppercase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'section header',
              'variant': 'label',
            })),
          ),
        ),
      );

      expect(find.text('SECTION HEADER'), findsOneWidget);
    });

    testWidgets('renders overline variant uppercase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'overline text',
              'variant': 'overline',
            })),
          ),
        ),
      );

      expect(find.text('OVERLINE TEXT'), findsOneWidget);
    });

    testWidgets('defaults to body variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'default text',
            })),
          ),
        ),
      );

      expect(find.textContaining('default text'), findsOneWidget);
    });

    testWidgets('technical variant accepts fontSize and color overrides', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'custom tech',
              'variant': 'technical',
              'fontSize': 16,
              'fontWeight': 800,
              'letterSpacing': 2.0,
              'color': '#00FF88',
            })),
          ),
        ),
      );

      expect(find.text('CUSTOM TECH'), findsOneWidget);
    });

    testWidgets('renders body2 variant as bodySmall', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: textOverrideCatalogBuilder(_MockContext({
              'text': 'small body text',
              'variant': 'body2',
            })),
          ),
        ),
      );

      expect(find.textContaining('small body text'), findsOneWidget);
    });
  });
}
