import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/ui/chat_screen.dart';
import 'package:clawfree/src/ui/theme.dart';
import 'package:clawfree/src/voice/voice_controller.dart';

/// Wraps ChatScreen in a constrained phone-width viewport (400x800) so tests
/// consistently hit the phone layout (< 600px).
///
/// Sets [SessionMode.agentBuilder] by default so tests get the standard chat UI.
Widget buildChatTestApp(
  ChatSession session, {
  VoiceController? voiceController,
  dynamic sttService,
  SessionMode mode = SessionMode.agentBuilder,
}) {
  session.setMode(mode);
  return MaterialApp(
    theme: ClawfreeTheme.light,
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        padding: EdgeInsets.only(top: 44), // Simulate iPhone status bar
        viewInsets: EdgeInsets.zero,
      ),
      child: ChatScreen(chatSession: session, sttService: sttService, showOnboarding: false),
    ),
  );
}

/// Sets the test viewport to a fixed size and pixel ratio, with automatic
/// teardown. Replaces the 3-line boilerplate pattern duplicated across tests.
void setTestViewport(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  double devicePixelRatio = 1.0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
