import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/card_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-card',
    type: 'Card',
    buildChild: (id, [dc]) => Text('CardChild: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Card override', () {
    testWidgets('renders glass variant by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return cardOverrideCatalogBuilder(
                  _createContext({'child': 'card-child'}, context),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('CardChild: card-child'), findsOneWidget);
    });

    testWidgets('renders flat variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return cardOverrideCatalogBuilder(
                  _createContext({'child': 'flat-child', 'variant': 'flat'}, context),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('CardChild: flat-child'), findsOneWidget);
    });

    testWidgets('renders elevated variant as Material Card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return cardOverrideCatalogBuilder(
                  _createContext({'child': 'elev-child', 'variant': 'elevated'}, context),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('CardChild: elev-child'), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink for non-string child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return cardOverrideCatalogBuilder(
                  _createContext({'child': 123}, context),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
