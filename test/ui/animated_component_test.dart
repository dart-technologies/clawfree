import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/animated_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-animated',
    type: 'Animated',
    buildChild: (id, [dc]) => Text('Animated: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Animated component', () {
    testWidgets('renders child with fadeIn animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => animatedCatalogBuilder(_createContext({
                'child': 'inner',
                'animation': 'fadeIn',
              }, context)),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Animated: inner'), findsOneWidget);
    });

    testWidgets('renders child with slideUp animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => animatedCatalogBuilder(_createContext({
                'child': 'slide-child',
                'animation': 'slideUp',
              }, context)),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Animated: slide-child'), findsOneWidget);
    });

    testWidgets('defaults to fadeIn when no animation specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => animatedCatalogBuilder(_createContext({
                'child': 'default-anim',
              }, context)),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Animated: default-anim'), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink for non-string child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            final widget = animatedCatalogBuilder(_createContext({
              'child': 123,
            }, context));
            return widget;
          }),
        ),
      );
      
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
