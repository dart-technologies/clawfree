import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/chat_session.dart';
import '../voice/stt_service.dart';
import '../voice/voice_controller.dart';
import 'chat/chat_input_bar.dart';
import 'chat/chat_message_list.dart';
import 'chat/chat_surface_panel.dart';
import 'clawfree_assets.dart';
import 'clawfree_icons.dart';
import 'theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatSession,
    this.sttService,
    this.voiceController,
    this.onNavigateHome,
  });

  final ChatSession chatSession;
  final SttService? sttService;
  final VoiceController? voiceController;
  final VoidCallback? onNavigateHome;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _handsFreeMode = false;

  ChatSession get _session => widget.chatSession;

  @override
  void initState() {
    super.initState();
    _session.addListener(_scrollToBottom);
  }

  void _toggleHandsFree() {
    setState(() {
      _handsFreeMode = !_handsFreeMode;
    });
    final vc = widget.voiceController;
    if (vc != null) {
      vc.continuousMode = _handsFreeMode;
    }
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _sendFromTextField,
        const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
            () => widget.onNavigateHome?.call(),
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _session,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: _handsFreeMode
                  ? ClawfreeTheme.lobsterOrange.withValues(alpha: 0.05)
                  : (isDark ? ClawfreeTheme.darkBg : ClawfreeTheme.lightBg),
              extendBodyBehindAppBar: true,
              appBar: _buildAppBar(context, isDark),
              body: SafeArea(
                top: false,
                child: _buildAdaptiveLayout(context),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar with frosted glass effect
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            leading: widget.onNavigateHome != null
                ? IconButton(
                    icon: Icon(ClawfreeIcons.back),
                    onPressed: widget.onNavigateHome,
                    tooltip: 'Back to Home (\u2318[)',
                  )
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'app-icon',
                  child: Image.asset(
                      ClawfreeAssets.icon, width: 28, height: 28),
                ),
                const SizedBox(width: 8),
                Text(
                  'clawfree',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_handsFreeMode) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ClawfreeTheme.lobsterOrange.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(ClawfreeTheme.radiusFull),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ClawfreeTheme.lobsterOrange,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (_session.isProcessing)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ClawfreeTheme.lobsterOrange,
                    ),
                  ),
                ),
              if (widget.sttService != null)
                _AnimatedIconButton(
                  icon: _handsFreeMode ? Icons.headset_mic : Icons.headset_off,
                  isActive: _handsFreeMode,
                  tooltip: _handsFreeMode
                      ? 'Exit hands-free mode'
                      : 'Enter hands-free mode',
                  onPressed: _toggleHandsFree,
                ),
              _AnimatedIconButton(
                icon: _session.ttsEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                isActive: _session.ttsEnabled,
                tooltip: _session.ttsEnabled
                    ? 'Disable TTS readback'
                    : 'Enable TTS readback',
                onPressed: () {
                  _session.ttsEnabled = !_session.ttsEnabled;
                },
              ),
              _buildExportButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  Widget _buildAdaptiveLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    // Account for the app bar height when extending behind it
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Row(
          children: [
            SizedBox(
              width: 400,
              child: Column(
                children: [
                  Expanded(
                    child: _buildMessageList(
                      maxBubbleWidth: 350,
                      isDesktop: true,
                    ),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              color: Theme.of(context).dividerTheme.color,
            ),
            Expanded(
              child: ChatSurfacePanel(
                surfaceMessages:
                    _session.messages.where((m) => m.isSurface).toList(),
                surfaceHost: _session.surfaceHost,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          Expanded(
            child: _buildMessageList(
              maxBubbleWidth: width * 0.8,
              isDesktop: false,
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList({
    required double maxBubbleWidth,
    required bool isDesktop,
  }) {
    return ChatMessageList(
      messages: _session.messages,
      scrollController: _scrollController,
      surfaceHost: _session.surfaceHost,
      maxBubbleWidth: maxBubbleWidth,
      isDesktop: isDesktop,
      isProcessing: _session.isProcessing,
      onSend: _send,
      onRetry: _session.retryLastMessage,
    );
  }

  Widget _buildInputBar() {
    return ChatInputBar(
      controller: _textController,
      sttService: widget.sttService,
      voiceController: widget.voiceController,
      isProcessing: _session.isProcessing,
      onSend: _send,
      handsFreeMode: _handsFreeMode,
    );
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Widget _buildExportButton() {
    return IconButton(
      icon: const Icon(ClawfreeIcons.download),
      tooltip: 'Export agent config',
      onPressed: () {
        final config = _session.exportAgentConfig();
        if (config != null) {
          final json = const JsonEncoder.withIndent('  ').convert(config);
          final agentName = config['name'] ?? 'Agent';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('$agentName (OpenClaw)'),
              content: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(ClawfreeIcons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No agent config to export. Create an agent first.'),
            ),
          );
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _sendFromTextField() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _send(text);
  }

  void _send(String text) {
    HapticFeedback.lightImpact();
    _session.sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: ClawfreeTheme.transitionDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _session.removeListener(_scrollToBottom);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Icon button with subtle active state indicator for AppBar actions.
class _AnimatedIconButton extends StatelessWidget {
  const _AnimatedIconButton({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: ClawfreeTheme.hoverDuration,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? ClawfreeTheme.lobsterOrange.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ClawfreeTheme.radiusS),
        ),
        child: IconButton(
          icon: Icon(icon),
          color: isActive ? ClawfreeTheme.lobsterOrange : null,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
