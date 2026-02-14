import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/button_component.dart';
import 'package:clawfree/src/ui/theme.dart';

class _MockDataContext extends Fake implements DataContext {}

class _MockContext extends Fake implements CatalogItemContext {
  _MockContext(this.data);
  @override
  final Object data;
  @override
  String get id => 'test-button';
  @override
  DataContext get dataContext => _MockDataContext();

  final dispatchedEvents = <UiEvent>[];
  @override
  DispatchEventCallback get dispatchEvent =>
      (UiEvent event) => dispatchedEvents.add(event);

  @override
  ChildBuilderCallback get buildChild =>
      (String id, [DataContext? dc]) => Text('BtnLabel: $id');
}

void main() {
  group('Button override', () {
    testWidgets('renders primary variant as ElevatedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: buttonOverrideCatalogBuilder(_MockContext({
              'child': 'btn-label',
              'action': <String, Object?>{
                'event': <String, Object?>{
                  'name': 'click',
                  'context': <String, Object?>{},
                },
              },
              'variant': 'primary',
            })),
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
            body: buttonOverrideCatalogBuilder(_MockContext({
              'child': 'secondary-btn',
              'action': <String, Object?>{
                'event': <String, Object?>{
                  'name': 'click',
                  'context': <String, Object?>{},
                },
              },
              'variant': 'secondary',
            })),
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
            body: buttonOverrideCatalogBuilder(_MockContext({
              'child': 'ghost-btn',
              'action': <String, Object?>{
                'event': <String, Object?>{
                  'name': 'click',
                  'context': <String, Object?>{},
                },
              },
              'variant': 'ghost',
            })),
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
            body: buttonOverrideCatalogBuilder(_MockContext({
              'child': 'send-btn',
              'action': <String, Object?>{
                'event': <String, Object?>{
                  'name': 'send',
                  'context': <String, Object?>{},
                },
              },
              'icon': 'send',
            })),
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
            body: buttonOverrideCatalogBuilder(_MockContext({
              'child': 42,
              'action': <String, Object?>{
                'event': <String, Object?>{'name': 'click'},
              },
            })),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
