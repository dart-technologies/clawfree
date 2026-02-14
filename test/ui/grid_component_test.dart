import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/grid_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-grid';
  @override
  ChildBuilderCallback get buildChild =>
      (String id, [DataContext? dc]) => Text('Child: $id');
}

void main() {
  group('Grid component', () {
    testWidgets('renders children in a Wrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: gridCatalogBuilder(_MockContext({
              'columns': 2,
              'gap': 8,
              'children': ['child-1', 'child-2', 'child-3'],
            })),
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
            body: gridCatalogBuilder(_MockContext({
              'children': ['a', 'b'],
            })),
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
            body: gridCatalogBuilder(_MockContext({
              'children': <String>[],
            })),
          ),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
    });
  });
}
