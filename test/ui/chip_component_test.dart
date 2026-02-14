import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/chip_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-chip',
    type: 'Chip',
    buildChild: (id, [dc]) => Text('ChipChild: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Chip component', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => chipCatalogBuilder(
                _createContext({'label': 'Flutter'}, context),
              ),
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
            body: Builder(
              builder: (context) => chipCatalogBuilder(
                _createContext({'label': 'Star', 'icon': 'star'}, context),
              ),
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
            body: Builder(
              builder: (context) => chipCatalogBuilder(
                _createContext({'label': 'Filled', 'variant': 'filled'}, context),
              ),
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
            body: Builder(
              builder: (context) => chipCatalogBuilder(
                _createContext({'label': 'Remove', 'deletable': true}, context),
              ),
            ),
          ),
        ),
      );

      final chip = tester.widget<InputChip>(find.byType(InputChip));
      expect(chip.onDeleted, isNotNull);
    });
  });
}
