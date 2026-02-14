import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/chip_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-chip';

  final dispatchedEvents = <UiEvent>[];
  @override
  DispatchEventCallback get dispatchEvent =>
      (UiEvent event) => dispatchedEvents.add(event);
}

void main() {
  group('Chip component', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: chipCatalogBuilder(
              _MockContext({'label': 'Flutter'}),
            ),
          ),
        ),
      );

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: chipCatalogBuilder(
              _MockContext({'label': 'Star', 'icon': 'star'}),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders filled variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: chipCatalogBuilder(
              _MockContext({'label': 'Filled', 'variant': 'filled'}),
            ),
          ),
        ),
      );

      expect(find.text('Filled'), findsOneWidget);
      final chip = tester.widget<InputChip>(find.byType(InputChip));
      expect(chip.side, BorderSide.none);
    });

    testWidgets('shows delete icon when deletable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: chipCatalogBuilder(
              _MockContext({'label': 'Remove', 'deletable': true}),
            ),
          ),
        ),
      );

      final chip = tester.widget<InputChip>(find.byType(InputChip));
      expect(chip.onDeleted, isNotNull);
    });
  });
}
