import 'package:clawfree/src/ui/health/health_state.dart';
import 'package:clawfree/src/ui/layouts/watch_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('WatchLayout', () {
    testWidgets('_HeartbeatScreen builds without error', (tester) async {
      await tester.pumpWidget(
        wrap(
          WatchLayout(
            healthLevel: HealthLevel.nominal,
            activeAgentCount: 2,
            pendingApprovals: const [],
            agentNames: const ['TestBot'],
            onStartSpeaking: () {},
            onApprove: (_) {},
            onDeny: (_) {},
            onPingAgent: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WatchLayout), findsOneWidget);
      expect(find.text('2 Agents Active'), findsOneWidget);
    });

    testWidgets('shows Tap to Speak initially', (tester) async {
      await tester.pumpWidget(
        wrap(
          WatchLayout(
            healthLevel: HealthLevel.nominal,
            activeAgentCount: 1,
            pendingApprovals: const [],
            agentNames: const [],
            onStartSpeaking: () {},
            onApprove: (_) {},
            onDeny: (_) {},
            onPingAgent: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Tap to Speak'), findsOneWidget);
    });

    testWidgets('singular agent count shows correct text', (tester) async {
      await tester.pumpWidget(
        wrap(
          WatchLayout(
            healthLevel: HealthLevel.nominal,
            activeAgentCount: 1,
            pendingApprovals: const [],
            agentNames: const [],
            onStartSpeaking: () {},
            onApprove: (_) {},
            onDeny: (_) {},
            onPingAgent: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1 Agent Active'), findsOneWidget);
    });

    testWidgets('pulse animation runs without error', (tester) async {
      await tester.pumpWidget(
        wrap(
          WatchLayout(
            healthLevel: HealthLevel.nominal,
            activeAgentCount: 0,
            pendingApprovals: const [],
            agentNames: const [],
            onStartSpeaking: () {},
            onApprove: (_) {},
            onDeny: (_) {},
            onPingAgent: (_) {},
          ),
        ),
      );
      // Pump several frames to exercise the animation controller
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WatchLayout), findsOneWidget);
    });
  });
}
