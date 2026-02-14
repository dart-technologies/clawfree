import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/responsive_container.dart';
import 'package:clawfree/src/ui/chat/chat_surface_view.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-responsive',
    type: 'ResponsiveContainer',
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
  group('ResponsiveContainer', () {
    testWidgets('renders children in columns on wide screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                child: Builder(
                  builder: (context) => ResponsiveContainer(
                    itemContext: _createContext({
                      'children': ['1', '2'],
                      'columns': 2,
                      'spacing': 10.0,
                    }, context),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child: 1'), findsOneWidget);
      expect(find.text('Child: 2'), findsOneWidget);

      // Wrap should be used for columns > 1
      expect(find.byType(Wrap), findsOneWidget);

      // Wait for stagger timers (0ms, 80ms)
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders children in a column on narrow screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: Builder(
                  builder: (context) => ResponsiveContainer(
                    itemContext: _createContext({
                      'children': ['1', '2'],
                      'columns': 2,
                      'mobileColumns': 1,
                      'spacing': 10.0,
                    }, context),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child: 1'), findsOneWidget);
      expect(find.text('Child: 2'), findsOneWidget);

      // Column should be used for activeColumns == 1
      expect(find.byType(Column), findsOneWidget);

      // Wait for stagger timers
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders skeleton when children are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ResponsiveContainer(
                itemContext: _createContext({
                  'children': [],
                  'skeleton': 'card',
                }, context),
              ),
            ),
          ),
        ),
      );

      // ShimmerSkeleton should be rendered
      expect(find.byType(ShimmerSkeleton), findsOneWidget);
    });
  });
}
