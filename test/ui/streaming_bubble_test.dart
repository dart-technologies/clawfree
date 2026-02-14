import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/ui/chat/chat_message_bubble.dart';
import 'package:clawfree/src/ui/theme.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/voice_controller.dart';

/// Diagnostic tests proving that the streaming pipeline delivers chunks
/// incrementally and that text accumulates in MessageItem.text over time.
///
/// These tests diagnose the "no visible typing effect" issue by:
/// 1. Verifying DemoCacheAiClient yields multiple chunks with delays
/// 2. Verifying ChatSession.sendMessage accumulates text incrementally
/// 3. Verifying the ChatMessageBubble receives updated text during streaming
void main() {
  group('Streaming pipeline: chunk delivery', () {
    test(
      'DemoCacheAiClient yields text in multiple chunks with delays',
      () async {
        final client = DemoCacheAiClient(
          chunkSize: 8,
          chunkDelay: const Duration(milliseconds: 20),
        );

        final chunks = <String>[];
        final timestamps = <int>[];

        await for (final chunk in client.sendStream(
          'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
          systemPrompt: '',
          history: [],
        )) {
          chunks.add(chunk);
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
        }

        // Should produce multiple chunks (text part split into chunkSize=8)
        expect(
          chunks.length,
          greaterThan(3),
          reason: 'Response text should be split into multiple small chunks',
        );

        // First chunks should be small text fragments
        for (var i = 0; i < chunks.length - 1; i++) {
          // Last chunk is the JSON block, earlier chunks are text
          if (!chunks[i].contains('```json')) {
            expect(
              chunks[i].length,
              lessThanOrEqualTo(8),
              reason: 'Text chunks should be at most chunkSize=8 chars',
            );
          }
        }

        // The last chunk should be the JSON block (agent form)
        expect(
          chunks.last,
          contains('```json'),
          reason: 'Final chunk should be the JSON A2UI block',
        );

        // Verify there were delays between chunks (at least some > 10ms apart)
        var delayedCount = 0;
        for (var i = 1; i < timestamps.length; i++) {
          if (timestamps[i] - timestamps[i - 1] >= 10) delayedCount++;
        }
        expect(
          delayedCount,
          greaterThan(0),
          reason: 'Should have real delays between text chunks',
        );
      },
    );

    test(
      'ChatSession accumulates text incrementally during streaming',
      () async {
        final client = DemoCacheAiClient(
          chunkSize: 8,
          chunkDelay: const Duration(milliseconds: 30),
        );
        final voiceController = VoiceController(
          stt: MockSttService(),
          tts: MockTtsService(),
        );
        final session = ChatSession(
          aiClient: client,
          voiceController: voiceController,
        );
        session.setMode(SessionMode.agentBuilder);

        // Capture intermediate text snapshots via listener
        final snapshots = <String>[];
        session.addListener(() {
          final aiMessages = session.messages.where(
            (m) => !m.isUser && !m.isSurface && (m.text ?? '').isNotEmpty,
          );
          if (aiMessages.isNotEmpty) {
            final current = aiMessages.last.text ?? '';
            if (snapshots.isEmpty || snapshots.last != current) {
              snapshots.add(current);
            }
          }
        });

        await session.sendMessage('help');
        // Allow debounce timers to flush
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should have captured multiple intermediate text states
        expect(
          snapshots.length,
          greaterThan(1),
          reason:
              'Text should accumulate incrementally across multiple '
              'notifyListeners calls (got ${snapshots.length} snapshots)',
        );

        // Each snapshot should be a prefix of the next (text only grows)
        for (var i = 1; i < snapshots.length; i++) {
          expect(
            snapshots[i].startsWith(snapshots[i - 1].trimRight()),
            isTrue,
            reason:
                'Snapshot $i should extend snapshot ${i - 1}:\n'
                '  prev: "${snapshots[i - 1]}"\n'
                '  curr: "${snapshots[i]}"',
          );
        }

        // Final text should be the complete response
        final finalText = snapshots.last;
        expect(
          finalText.length,
          greaterThan(20),
          reason: 'Final accumulated text should be substantial',
        );

        session.dispose();
      },
    );
  });

  group('Streaming bubble: visual indicator', () {
    testWidgets('ChatMessageBubble renders streaming cursor when isStreaming', (
      WidgetTester tester,
    ) async {
      final message = MessageItem.aiText(text: 'Hello wor');

      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.dark,
          home: Scaffold(
            body: ChatMessageBubble(
              message: message,
              maxBubbleWidth: 300,
              isStreaming: true,
            ),
          ),
        ),
      );

      // The streaming cursor character should be visible
      expect(
        find.textContaining('\u258C'),
        findsOneWidget,
        reason: 'Streaming bubble should show blinking cursor',
      );

      // Pump some frames to verify animation runs
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('ChatMessageBubble hides cursor when not streaming', (
      WidgetTester tester,
    ) async {
      final message = MessageItem.aiText(text: 'Hello world!');

      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.dark,
          home: Scaffold(
            body: ChatMessageBubble(
              message: message,
              maxBubbleWidth: 300,
              isStreaming: false,
            ),
          ),
        ),
      );

      // No cursor when not streaming
      expect(
        find.textContaining('\u258C'),
        findsNothing,
        reason: 'Non-streaming bubble should not show cursor',
      );
    });

    testWidgets('ChatMessageBubble text updates during streaming', (
      WidgetTester tester,
    ) async {
      final message = MessageItem.aiText(text: 'Hel');

      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.dark,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ChatMessageBubble(
                      message: message,
                      maxBubbleWidth: 300,
                      isStreaming: true,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        message.text = 'Hello World';
                      }),
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially shows partial text
      expect(find.textContaining('Hel'), findsOneWidget);

      // Tap button to simulate text update
      await tester.tap(find.text('Update'));
      await tester.pump();

      // Now shows updated text
      expect(find.textContaining('Hello World'), findsOneWidget);
    });
  });
}
