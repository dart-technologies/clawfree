import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/chat_message_list.dart';
import 'package:clawfree/src/ui/chat/chat_surface_panel.dart';
import 'package:clawfree/src/ui/chat/chat_surface_view.dart';
import 'package:clawfree/src/core/message_item.dart';

class MockSurfaceContext extends Fake implements SurfaceContext {
  @override
  String get surfaceId => 'test';

  @override
  ValueListenable<SurfaceDefinition?> get definition => ValueNotifier(null);
}

class MockSurfaceHost extends Fake implements SurfaceHost {
  @override
  SurfaceContext contextFor(String surfaceId) => MockSurfaceContext();

  @override
  Stream<SurfaceUpdate> get surfaceUpdates => const Stream.empty();

  @override
  ValueListenable<SurfaceDefinition?> watchSurface(String surfaceId) {
    return ValueNotifier<SurfaceDefinition?>(null);
  }
}

void main() {
  group('ChatMessageList', () {
    late ScrollController scrollController;
    late SurfaceHost surfaceHost;

    setUp(() {
      scrollController = ScrollController();
      surfaceHost = MockSurfaceHost();
    });

    tearDown(() {
      scrollController.dispose();
    });

    testWidgets('renders empty state when no messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageList(
              messages: const [],
              scrollController: scrollController,
              surfaceHost: surfaceHost,
              maxBubbleWidth: 400,
              isDesktop: false,
              isProcessing: false,
              onSend: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Say something to get started'), findsOneWidget);
      expect(find.text('Create an agent'), findsOneWidget);
    });

    testWidgets('renders list of messages', (WidgetTester tester) async {
      final messages = [
        MessageItem.user(text: 'Hello'),
        MessageItem.aiText(text: 'Hi there!'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageList(
              messages: messages,
              scrollController: scrollController,
              surfaceHost: surfaceHost,
              maxBubbleWidth: 400,
              isDesktop: false,
              isProcessing: false,
              onSend: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
    });

    testWidgets('renders surface messages on mobile', (WidgetTester tester) async {
      final messages = [
        MessageItem.surface(surfaceId: 'test-surface'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageList(
              messages: messages,
              scrollController: scrollController,
              surfaceHost: surfaceHost,
              maxBubbleWidth: 400,
              isDesktop: false,
              isProcessing: false,
              onSend: (_) {},
            ),
          ),
        ),
      );

      // ChatSurfaceView shows a skeleton when UI is null (which it is in our mock)
      expect(find.byType(ChatSurfaceView), findsOneWidget);

      // Clear the 80ms timer in ChatSurfaceView
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders SurfaceIndicator on desktop', (WidgetTester tester) async {
       final messages = [
        MessageItem.surface(surfaceId: 'test-surface'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageList(
              messages: messages,
              scrollController: scrollController,
              surfaceHost: surfaceHost,
              maxBubbleWidth: 400,
              isDesktop: true,
              isProcessing: false,
              onSend: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SurfaceIndicator), findsOneWidget);

      // Even if not using ChatSurfaceView, ensure no pending timers if it was built
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('tapping suggestion chip calls onSend', (WidgetTester tester) async {
      String? sentText;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageList(
              messages: const [],
              scrollController: scrollController,
              surfaceHost: surfaceHost,
              maxBubbleWidth: 400,
              isDesktop: false,
              isProcessing: false,
              onSend: (text) => sentText = text,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Create an agent'));
      await tester.pump();

      expect(sentText, 'Create an agent');
    });
  });
}
