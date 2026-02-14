import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/button_component.dart';
import 'package:clawfree/src/ui/theme.dart';

CatalogItemContext _createContext(Object data, BuildContext context) {
  return CatalogItemContext(
    data: data,
    id: 'test-button',
    type: 'Button',
    buildChild: (id, [dc]) => Text('BtnLabel: $id'),
    dispatchEvent: (event) {},
    buildContext: context,
    dataContext: DataContext(DataModel(), '/'),
    getComponent: (id) => null,
    getCatalogItem: (type) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Button override', () {
    testWidgets('renders primary variant as ElevatedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => buttonOverrideCatalogBuilder(_createContext({
                'child': 'btn-label',
                'action': <String, Object?>{
                  'event': <String, Object?>{
                    'name': 'click',
                    'context': <String, Object?>{},
                  },
                },
                'variant': 'primary',
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('BtnLabel: btn-label'), findsOneWidget);
    });

    testWidgets('renders secondary variant as OutlinedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => buttonOverrideCatalogBuilder(_createContext({
                'child': 'secondary-btn',
                'action': <String, Object?>{
                  'event': <String, Object?>{
                    'name': 'click',
                    'context': <String, Object?>{},
                  },
                },
                'variant': 'secondary',
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders ghost variant as TextButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => buttonOverrideCatalogBuilder(_createContext({
                'child': 'ghost-btn',
                'action': <String, Object?>{
                  'event': <String, Object?>{
                    'name': 'click',
                    'context': <String, Object?>{},
                  },
                },
                'variant': 'ghost',
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => buttonOverrideCatalogBuilder(_createContext({
                'child': 'send-btn',
                'action': <String, Object?>{
                  'event': <String, Object?>{
                    'name': 'send',
                    'context': <String, Object?>{},
                  },
                },
                'icon': 'send',
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink for non-string child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => buttonOverrideCatalogBuilder(_createContext({
                'child': 42,
                'action': <String, Object?>{
                  'event': <String, Object?>{'name': 'click'},
                },
              }, context)),
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
