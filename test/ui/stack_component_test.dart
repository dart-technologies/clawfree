import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/stack_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-stack',
    type: 'Stack',
    buildChild: (id, [dc]) => Text('Layer: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Stack component', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Builder(
                builder: (context) => stackCatalogBuilder(_createContext({
                  'children': ['bg', 'fg'],
                }, context)),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Layer: bg'), findsOneWidget);
      expect(find.text('Layer: fg'), findsOneWidget);
      // ClipRRect wraps the Stack
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('uses center alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Builder(
                builder: (context) => stackCatalogBuilder(_createContext({
                  'alignment': 'center',
                  'children': ['item'],
                }, context)),
              ),
            ),
          ),
        ),
      );

      // Find the Stack under the ClipRRect
      final clipRRect = find.byType(ClipRRect);
      expect(clipRRect, findsOneWidget);
      final clipWidget = tester.widget<ClipRRect>(clipRRect);
      final stack = clipWidget.child! as Stack;
      expect(stack.alignment, Alignment.center);
    });

    testWidgets('returns SizedBox.shrink when no children', (tester) async {
      late Widget widget;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            widget = stackCatalogBuilder(_createContext({
              'children': <String>[],
            }, context));
            return Container();
          }),
        ),
      );

      // Should be a SizedBox (shrink) directly
      expect(widget, isA<SizedBox>());
    });
  });
}
