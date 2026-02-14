import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/grid_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-grid',
    type: 'Grid',
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
  group('Grid component', () {
    testWidgets('renders children in a Wrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => gridCatalogBuilder(_createContext({
                'columns': 2,
                'gap': 8,
                'children': ['child-1', 'child-2', 'child-3'],
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Child: child-1'), findsOneWidget);
      expect(find.text('Child: child-2'), findsOneWidget);
      expect(find.text('Child: child-3'), findsOneWidget);
    });

    testWidgets('defaults to 2 columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => gridCatalogBuilder(_createContext({
                'children': ['a', 'b'],
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when no children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => gridCatalogBuilder(_createContext({
                'children': <String>[],
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
    });
  });
}
