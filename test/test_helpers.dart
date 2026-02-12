import 'package:flutter/material.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/ui/chat_screen.dart';
import 'package:clawfree/src/ui/theme.dart';
import 'package:clawfree/src/voice/stt_service.dart';

/// Wraps ChatScreen in a constrained phone-width viewport (400x800) so tests
/// consistently hit the phone layout (< 600px).
///
/// Sets [SessionMode.agentBuilder] by default so tests get the standard chat UI.
Widget buildChatTestApp(
  ChatSession session, {
  SttService? sttService,
  SessionMode mode = SessionMode.agentBuilder,
}) {
  session.setMode(mode);
  return MaterialApp(
    theme: ClawfreeTheme.light,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: ChatScreen(chatSession: session, sttService: sttService),
    ),
  );
}
