import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../../core/prompt_library.dart';
import '../../core/remote_session.dart';
import '../../voice/voice_controller.dart';
import '../clawfree_icons.dart';
import '../chat/chat_input_bar.dart';
import '../chat/chat_surface_view.dart';
import '../health/health_indicators.dart';
import 'voice_orb.dart';

import '../chat/recent_chat_overlay.dart';

/// iPhone "Mobile Remote" layout.
///
/// Features genUI prominently in the background.
/// Recent chat bubbles are overlaid at the bottom.
/// Bottom contains a MicTray with VoiceOrb.
class PhoneLayout extends StatefulWidget {
  const PhoneLayout({
    super.key,
    required this.messages,
    required this.surfaceHost,
    required this.scrollController,
    required this.textController,
    required this.voiceController,
    required this.isProcessing,
    required this.healthState,
    required this.isListening,
    required this.interimTranscript,
    required this.isHomeDashboard,
    required this.activeAgentName,
    required this.handsFreeEnabled,
    required this.onSend,
    required this.onRetry,
    required this.onToggleVoice,
    required this.onToggleHandsFree,
    required this.onQuickAction,
    this.onPairDevice,
    this.sessionMode = SessionMode.home,
    this.activeSurfaceId,
    this.remoteSessions = const [],
    this.agentNames = const [],
    this.mood = OrbMood.idle,
  });

  final SessionMode sessionMode;
  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final ScrollController scrollController;
  final TextEditingController textController;
  final VoiceController? voiceController;
  final bool isProcessing;
  final HealthState healthState;
  final bool isListening;
  final String interimTranscript;
  final bool isHomeDashboard;
  final String? activeAgentName;
  final List<String> agentNames;
  final bool handsFreeEnabled;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;
  final VoidCallback onToggleVoice;
  final VoidCallback onToggleHandsFree;
  final ValueChanged<String> onQuickAction;
  final VoidCallback? onPairDevice;
  final String? activeSurfaceId;
  final List<RemoteSession> remoteSessions;
  final OrbMood mood;

  @override
  State<PhoneLayout> createState() => _PhoneLayoutState();
}

class _PhoneLayoutState extends State<PhoneLayout> {
  Color _accentForMode(BuildContext context) {
    return switch (widget.sessionMode) {
      SessionMode.onboarding => const Color(0xFF9C27B0),
      SessionMode.home => const Color(0xFF2196F3),
      SessionMode.agentBuilder => Theme.of(context).colorScheme.primary,
    };
  }

  Widget _chip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onSend(text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // Find the latest surface to display
    final surfaces = widget.messages.where((m) => m.isSurface).toList();
    MessageItem? latestSurface = surfaces.isNotEmpty ? surfaces.last : null;
    if (widget.activeSurfaceId != null) {
      final match = surfaces.where(
        (m) => m.surfaceId == widget.activeSurfaceId,
      );
      if (match.isNotEmpty) latestSurface = match.first;
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // -- Section 2: genUI Surface (60% of vertical) --
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLow
                  .withValues(alpha: 0.3),
              child: latestSurface != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: ChatSurfaceView(
                        surfaceId: latestSurface.surfaceId!,
                        surfaceHost: widget.surfaceHost,
                      ),
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.messages.isEmpty) ...[
                              Icon(
                                ClawfreeIcons.mic,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Say something to get started',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  _chip(context, 'Create an agent'),
                                  _chip(context, 'Show my agents'),
                                  _chip(context, 'Manage OpenClaw'),
                                ],
                              ),
                            ] else if (latestSurface == null) ...[
                              Icon(
                                ClawfreeIcons.mic,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // -- Section 3: Chat & Listening Tray (40% max vertical) --
          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Recent Chat Bubbles (Fixed at top of this section if few, scrolls if many)
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: RecentChatOverlay(
                        messages: widget.messages,
                        maxBubbleWidth: width * 0.8,
                        isProcessing: widget.isProcessing,
                      ),
                    ),
                  ),
                  // Unified Listen/Type Bar (Fixed at bottom)
                  ChatInputBar(
                    textController: widget.textController,
                    voiceController: widget.voiceController,
                    isProcessing: widget.isProcessing,
                    onSend: widget.onSend,
                    mood: widget.mood,
                    accentColor: _accentForMode(context),
                    handsFreeEnabled: widget.handsFreeEnabled,
                    onToggleHandsFree: widget.onToggleHandsFree,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Connectivity bar removed - handled by AppBar in ChatScreen for iPhone
