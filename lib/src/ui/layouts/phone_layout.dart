import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../../core/prompt_library.dart';
import '../../core/remote_session.dart';
import '../../voice/voice_controller.dart';
import '../chat/chat_input_bar.dart';
import '../chat/chat_surface_view.dart';
import '../health/health_indicators.dart';
import '../theme.dart';
import '../widgets/empty_state_view.dart';
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
    this.inputKey,
    this.inputFocusNode,
    this.sessionMode = SessionMode.home,
    this.activeSurfaceId,
    this.remoteSessions = const [],
    this.agentNames = const [],
    this.mood = OrbMood.idle,
  });

  final Key? inputKey;
  final FocusNode? inputFocusNode;
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

class _PhoneLayoutState extends State<PhoneLayout> with TickerProviderStateMixin {
  final ScrollController _surfaceScrollController = ScrollController();

  // Tray expansion state
  late double _historyHeight;
  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    // Default history height is 0 if no messages yet
    _historyHeight = widget.messages.any((m) => !m.isSurface) ? 200 : 0;
    
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _snapAnimation = AlwaysStoppedAnimation(_historyHeight);
  }

  @override
  void didUpdateWidget(PhoneLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand tray when the first text message arrives
    final hadText = oldWidget.messages.any((m) => !m.isSurface);
    final hasText = widget.messages.any((m) => !m.isSurface);

    if (!hadText && hasText && _historyHeight == 0) {
      _animateToHeight(200);
    }

    // Reset surface scroll to top when a new surface appears
    if (widget.activeSurfaceId != oldWidget.activeSurfaceId &&
        _surfaceScrollController.hasClients) {
      _surfaceScrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _surfaceScrollController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double maxHeight) {
    setState(() {
      // Dragging up (negative dy) increases height
      _historyHeight -= details.delta.dy;
      _historyHeight = _historyHeight.clamp(0.0, maxHeight);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details, double maxHeight) {
    final velocity = details.primaryVelocity ?? 0;
    
    double targetHeight;
    if (velocity < -300) {
      targetHeight = maxHeight; // Flick up to expand (lowered threshold)
    } else if (velocity > 300) {
      targetHeight = 0; // Flick down to collapse (lowered threshold)
    } else if (_historyHeight > maxHeight * 0.4) {
      targetHeight = maxHeight; // Snaps to expanded if past 40%
    } else if (_historyHeight < 80) {
      targetHeight = 0; // Snaps to collapsed if dragged very low
    } else {
      targetHeight = 200; // Normal state
    }

    _animateToHeight(targetHeight);
  }

  void _animateToHeight(double target) {
    _snapAnimation = Tween<double>(
      begin: _historyHeight,
      end: target,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    ));

    _snapController.forward(from: 0).then((_) {
      setState(() => _historyHeight = target);
    });

    _snapController.addListener(_updateFromAnimation);
  }

  void _updateFromAnimation() {
    setState(() => _historyHeight = _snapAnimation.value);
  }

  Color _accentForMode(BuildContext context) {
    return switch (widget.sessionMode) {
      SessionMode.onboarding => ClawfreeTheme.onboardingMode,
      SessionMode.home => ClawfreeTheme.homeMode,
      SessionMode.agentBuilder => ClawfreeTheme.agentBuilderMode,
    };
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          // Account for handle, spacing, input bar, and safe margin to avoid overflow
          const staticElementsHeight = 160.0;
          final maxHistoryHeight = (availableHeight - staticElementsHeight).clamp(0.0, availableHeight);
          final effectiveHistoryHeight = _historyHeight.clamp(0.0, maxHistoryHeight);

          return Stack(
            children: [
              // -- Layer 1: genUI Surface (Full screen background canvas) --
              Positioned.fill(
                child: latestSurface != null
                    ? RawScrollbar(
                        controller: _surfaceScrollController,
                        thumbColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        radius: const Radius.circular(8),
                        thickness: 4,
                        padding: const EdgeInsets.only(bottom: 340),
                        child: SingleChildScrollView(
                          controller: _surfaceScrollController,
                          primary: false,
                          padding: const EdgeInsets.fromLTRB(16, 64, 16, 440),
                          child: ChatSurfaceView(
                            key: Key('phone-surface-${latestSurface.surfaceId}'),
                            surfaceId: latestSurface.surfaceId!,
                            surfaceHost: widget.surfaceHost,
                          ),
                        ),
                      )
                    : EmptyStateView(onSend: widget.onSend, agentNames: widget.agentNames),
              ),

              // -- Layer 2: Chat & Listening Tray (Overlay bottom - Floating Capsule) --
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, maxHistoryHeight),
                    onVerticalDragEnd: (d) => _onVerticalDragEnd(d, maxHistoryHeight),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: ClawfreeTheme.glassBlur,
                          sigmaY: ClawfreeTheme.glassBlur,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            color: ClawfreeTheme.glassOverlayColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Drag Handle (Increased hit area)
                              Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: ClawfreeBorderRadius.pill,
                                ),
                              ),
                                                                                          // Recent Chat Bubbles (Dynamic height)
                                                                                          SizedBox(
                                                                                            height: effectiveHistoryHeight,
                                                                                            child: effectiveHistoryHeight > 0
                                                                                                ? SingleChildScrollView(
                                                                                                    controller: widget.scrollController,
                                                                                                    primary: false,
                                                                                                    reverse: true,
                                                                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                                                    child: RecentChatOverlay(
                                                                                                      messages: widget.messages,
                                                                                                      maxBubbleWidth: width * 0.8,
                                                                                                      isProcessing: widget.isProcessing,
                                                                                                    ),
                                                                                                  )
                                                                                                : const SizedBox.shrink(),
                                                                                          ),
                                                                                          if (effectiveHistoryHeight > 0) const SizedBox(height: 8),
                                                            
                              // Unified Listen/Type Bar (System Pill)
                              ChatInputBar(
                                key: widget.inputKey,
                                focusNode: widget.inputFocusNode,
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
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
