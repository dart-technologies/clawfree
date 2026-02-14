import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/stack_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-stack';
  @override
  ChildBuilderCallback get buildChild =>
      (String id, [DataContext? dc]) => Text('Layer: $id');
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
              child: stackCatalogBuilder(_MockContext({
                'children': ['bg', 'fg'],
              })),
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
              child: stackCatalogBuilder(_MockContext({
                'alignment': 'center',
                'children': ['item'],
              })),
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
      final widget = stackCatalogBuilder(_MockContext({
        'children': <String>[],
      }));

      // Should be a SizedBox (shrink) directly
      expect(widget, isA<SizedBox>());
    });
  });
}
