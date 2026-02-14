import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/progress_bar_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-progress',
    type: 'ProgressBar',
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
  group('ProgressBar component', () {
    testWidgets('renders with default settings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => progressBarCatalogBuilder(
                _createContext({'value': 0.5}, context),
              ),
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
            body: Builder(
              builder: (context) => progressBarCatalogBuilder(
                _createContext({'value': 0.75, 'label': 'UPLOAD'}, context),
              ),
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
            body: Builder(
              builder: (context) => progressBarCatalogBuilder(
                _createContext({
                  'value': 0.42,
                  'showPercentage': true,
                }, context),
              ),
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
            body: Builder(
              builder: (context) => progressBarCatalogBuilder(
                _createContext({'value': 1.5, 'showPercentage': true}, context),
              ),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });
  });
}
