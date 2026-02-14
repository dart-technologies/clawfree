import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/animated_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-animated';
  @override
  ChildBuilderCallback get buildChild =>
      (String id, [DataContext? dc]) => Text('Animated: $id');
}

void main() {
  group('Animated component', () {
    testWidgets('renders child with fadeIn animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: animatedCatalogBuilder(_MockContext({
              'child': 'inner',
              'animation': 'fadeIn',
            })),
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
            body: animatedCatalogBuilder(_MockContext({
              'child': 'slide-child',
              'animation': 'slideUp',
            })),
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
            body: animatedCatalogBuilder(_MockContext({
              'child': 'default-anim',
            })),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Animated: default-anim'), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink for non-string child', (tester) async {
      final widget = animatedCatalogBuilder(_MockContext({
        'child': 123,
      }));

      // Direct check — should be SizedBox.shrink
      expect(widget, isA<SizedBox>());
    });
  });
}
