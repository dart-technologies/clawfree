import 'package:clawfree/src/ui/layouts/voice_orb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceOrb haptic heartbeat', () {
    testWidgets('does not crash with isListening: true for 2 seconds', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: VoiceOrb(isListening: true))),
        ),
      );

      // Advance time to let the haptic timer fire several times
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 750));
      }

      // No crash means success
      expect(find.byType(VoiceOrb), findsOneWidget);
    });

    testWidgets('timer is cancelled when isListening switches to false', (
      tester,
    ) async {
      bool listening = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    VoiceOrb(isListening: listening),
                    TextButton(
                      onPressed: () => setState(() => listening = false),
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Let the timer fire once
      await tester.pump(const Duration(milliseconds: 750));

      // Stop listening
      await tester.tap(find.text('Stop'));
      await tester.pump();

      // Advance well past the timer period — should not crash
      await tester.pump(const Duration(milliseconds: 2000));

      expect(find.byType(VoiceOrb), findsOneWidget);
    });

    testWidgets('idle orb renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: VoiceOrb(isListening: false))),
        ),
      );

      expect(find.byType(VoiceOrb), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });
  });
}
