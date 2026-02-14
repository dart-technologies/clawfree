import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/card_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data, this._buildContext);
  @override
  final Object data;
  final BuildContext _buildContext;
  @override
  BuildContext get buildContext => _buildContext;
  @override
  String get id => 'test-card';
  @override
  ChildBuilderCallback get buildChild =>
      (String id, [DataContext? dc]) => Text('CardChild: $id');
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
                  _MockContext({'child': 'card-child'}, context),
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
                  _MockContext({'child': 'flat-child', 'variant': 'flat'}, context),
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
                  _MockContext({'child': 'elev-child', 'variant': 'elevated'}, context),
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
                  _MockContext({'child': 123}, context),
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
