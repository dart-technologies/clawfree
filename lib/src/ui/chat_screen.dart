import 'dart:convert';

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
    // Enable continuous mode when entering hands-free.
    final vc = widget.voiceController;
    if (vc != null) {
      vc.continuousMode = _handsFreeMode;
    }
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
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
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3)
                  : null,
              appBar: AppBar(
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
                    Text(_handsFreeMode ? 'clawfree 🎙️' : 'clawfree'),
                  ],
                ),
                actions: [
                  if (_session.isProcessing)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context)
                              .appBarTheme
                              .foregroundColor,
                        ),
                      ),
                    ),
                  // Hands-free toggle button
                  if (widget.sttService != null)
                    IconButton(
                      icon: Icon(
                        _handsFreeMode ? Icons.headset_mic : Icons.headset_off,
                        color: _handsFreeMode
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: _handsFreeMode
                          ? 'Exit hands-free mode'
                          : 'Enter hands-free mode',
                      onPressed: _toggleHandsFree,
                    ),
                  IconButton(
                    icon: Icon(
                      _session.ttsEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                    ),
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
              body: SafeArea(
                child: _buildAdaptiveLayout(context),
              ),
            );
          },
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

    if (isDesktop) {
      return Row(
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
          const VerticalDivider(width: 1),
          Expanded(
            child: ChatSurfacePanel(
              surfaceMessages:
                  _session.messages.where((m) => m.isSurface).toList(),
              surfaceHost: _session.surfaceHost,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildMessageList(
            maxBubbleWidth: width * 0.8,
            isDesktop: false,
          ),
        ),
        _buildInputBar(),
      ],
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
          duration: const Duration(milliseconds: 300),
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
