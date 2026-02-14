import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/progress_bar_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-progress';
}

void main() {
  group('ProgressBar component', () {
    testWidgets('renders with default settings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: progressBarCatalogBuilder(
              _MockContext({'value': 0.5}),
            ),
          ),
        ),
      );

      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('shows label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: progressBarCatalogBuilder(
              _MockContext({'value': 0.75, 'label': 'UPLOAD'}),
            ),
          ),
        ),
      );

      expect(find.text('UPLOAD'), findsOneWidget);
    });

    testWidgets('shows percentage when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: progressBarCatalogBuilder(
              _MockContext({
                'value': 0.42,
                'showPercentage': true,
              }),
            ),
          ),
        ),
      );

      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('clamps value to 0-1 range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: progressBarCatalogBuilder(
              _MockContext({'value': 1.5, 'showPercentage': true}),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });
  });
}
