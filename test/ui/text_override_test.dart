import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/text_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-text',
    type: 'Text',
    buildChild: (id, [dc]) => Text('Child: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Text override', () {
    testWidgets('renders body variant with markdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'Hello world',
                'variant': 'body',
              }, context)),
            ),
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
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'status ok',
                'variant': 'technical',
              }, context)),
            ),
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
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'section header',
                'variant': 'label',
              }, context)),
            ),
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
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'overline text',
                'variant': 'overline',
              }, context)),
            ),
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
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'default text',
              }, context)),
            ),
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
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'custom tech',
                'variant': 'technical',
                'fontSize': 16,
                'fontWeight': 800,
                'letterSpacing': 2.0,
                'color': '#00FF88',
              }, context)),
            ),
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
            body: Builder(
              builder: (context) => textOverrideCatalogBuilder(_createContext({
                'text': 'small body text',
                'variant': 'body2',
              }, context)),
            ),
          ),
        ),
      );

      expect(find.textContaining('small body text'), findsOneWidget);
    });
  });
}
