import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/chat_session.dart';
import '../core/platform_config.dart';
import '../core/prompt_library.dart';
import '../core/remote_session.dart';
import '../voice/stt_service.dart';
import 'chat_screen_dialogs.dart';
import 'clawfree_assets.dart';
import 'clawfree_icons.dart';
import 'health/health_indicators.dart';
import 'layouts/phone_layout.dart';
import 'layouts/tablet_layout.dart';
import 'layouts/watch_layout.dart';
import 'layouts/voice_orb.dart';
import 'mixins/health_monitor_mixin.dart';
import 'mixins/watch_sync_manager.dart';
import 'theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatSession,
    this.sttService,
    this.onNavigateHome,
  });

  final ChatSession chatSession;
  final SttService? sttService;
  final VoidCallback? onNavigateHome;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with HealthMonitorMixin, WatchSyncManager {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  ChatSession get _session => widget.chatSession;

  bool _handsFreeEnabled = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _session.onPairingRequested = _showPairingModal;
    _session.onNavigateBack = () => widget.onNavigateHome?.call();

    if (_session.gatewayClient != null) {
      initHealthMonitor(_session.gatewayClient!);

      initWatchSync(
        healthPoller: healthPoller!,
        agentStore: _session.agentStore,
      );
    }
  }

  void _onSessionChanged() {
    _scrollToBottom();
    if (mounted) setState(() {});
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
          listenable: Listenable.merge([_session, _session.voiceController]),
          builder: (context, _) {
            final isPhone =
                PlatformConfig.formFactor(context) == DeviceFormFactor.phone;

            if (isPhone) {
              return Scaffold(
                drawer: ChatScreenDialogs.buildDrawer(
                  context,
                  session: _session,
                  onSend: _send,
                  onExportConfig: () =>
                      ChatScreenDialogs.showExportConfig(context, _session),
                  onShowPairing: _showPairingModal,
                ),
                body: _buildPhoneLayout(context),
              );
            }

            return Scaffold(
              appBar: _buildAppBar(context),
              drawer: null,
              body: SafeArea(child: _buildAdaptiveLayout(context)),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildPhoneLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    final effectiveSessions = remoteSessions.isNotEmpty
        ? remoteSessions
        : (_session.gatewayClient == null
            ? defaultDemoSessions(PlatformConfig.formFactor(context))
            : <RemoteSession>[]);

    return Stack(
      children: [
        // -- Layer 1: Main Content --
        Padding(
          padding: EdgeInsets.only(top: topPadding + 44),
          child: _buildAdaptiveLayout(context),
        ),

        // -- Layer 2: Status Overlay (Dynamic Island Area) --
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: topPadding > 0 ? topPadding - 18 : 12,
            ),
            height: topPadding > 0 ? topPadding : 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 32),
                HealthDotBar(
                  state: HealthState(
                    gateway: healthState.gateway,
                    llm: healthState.llm,
                    channels: healthState.channels,
                  ),
                ),
                const Spacer(),
                for (final session in effectiveSessions) ...[
                  Icon(
                    iconForDeviceType(session.deviceType),
                    size: 14,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 32),
              ],
            ),
          ),
        ),

        // -- Layer 3: Centered Logo/Title + Menu --
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          height: 44,
          child: Container(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 20),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onNavigateHome,
                  borderRadius: ClawfreeBorderRadius.interactive,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(tag: 'app-icon', child: ClawfreeLogo(size: 24)),
                      const SizedBox(width: 6),
                      const Text(
                        'clawfree',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_session.isProcessing)
                  Positioned(
                    right: 12,
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: InkWell(
        onTap: widget.onNavigateHome,
        borderRadius: ClawfreeBorderRadius.interactive,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(tag: 'app-icon', child: ClawfreeLogo(size: 32)),
              const SizedBox(width: 8),
              const Text(
                'clawfree',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
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
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(ClawfreeIcons.download),
          tooltip: 'Export agent config',
          onPressed: () =>
              ChatScreenDialogs.showExportConfig(context, _session),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Layout dispatch
  // ---------------------------------------------------------------------------

  Widget _buildAdaptiveLayout(BuildContext context) {
    final formFactor = PlatformConfig.formFactor(context);
    _session.deviceFormFactor = formFactor;

    switch (formFactor) {
      case DeviceFormFactor.phone:
        return _buildPhoneContent(context);
      case DeviceFormFactor.tablet:
      case DeviceFormFactor.desktop:
        return _buildTabletLayout(context);
      case DeviceFormFactor.watch:
      case DeviceFormFactor.glasses:
        return _buildWatchLayout();
    }
  }

  Widget _buildPhoneContent(BuildContext context) {
    final agents = _session.agentStore.agents;
    final activeAgent =
        agents.isNotEmpty ? agents.last['name'] as String? : null;

    final isListening = _session.voiceController?.isListening ?? false;
    final isSpeaking = _session.voiceController?.isSpeaking ?? false;
    final isProcessing = _session.isProcessing;

    OrbMood mood = OrbMood.idle;
    if (_session.successMoodActive) {
      mood = OrbMood.success;
    } else if (_session.messages.isNotEmpty &&
        _session.messages.last.isError) {
      mood = OrbMood.error;
    } else if (isListening) {
      mood = OrbMood.listening;
    } else if (isSpeaking) {
      mood = OrbMood.speaking;
    } else if (isProcessing) {
      mood = OrbMood.thinking;
    }

    return PhoneLayout(
      sessionMode: _session.sessionMode,
      messages: _session.messages,
      activeSurfaceId: _session.activeSurfaceId,
      surfaceHost: _session.surfaceHost,
      scrollController: _scrollController,
      textController: _textController,
      voiceController: _session.voiceController,
      isProcessing: isProcessing,
      healthState: healthState,
      isListening: isListening,
      interimTranscript: _session.voiceController?.interimTranscript ?? '',
      isHomeDashboard: _session.sessionMode == SessionMode.home,
      activeAgentName: activeAgent,
      agentNames:
          agents.map((a) => a['name'] as String? ?? 'Untitled').toList(),
      handsFreeEnabled: _handsFreeEnabled,
      remoteSessions: remoteSessions,
      onSend: _send,
      onRetry: _session.retryLastMessage,
      onToggleVoice: _toggleVoice,
      onToggleHandsFree: _toggleHandsFree,
      onQuickAction: _send,
      onPairDevice: () => _showPairingModal(_session.pairingUrl),
      mood: mood,
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final agents = _session.agentStore.agents;
    final agentNames =
        agents.map((a) => a['name'] as String? ?? 'Untitled').toList();

    final effectiveSessions = remoteSessions.isNotEmpty
        ? remoteSessions
        : (_session.gatewayClient == null
            ? defaultDemoSessions(PlatformConfig.formFactor(context))
            : <RemoteSession>[]);

    return TabletLayout(
      messages: _session.messages,
      activeSurfaceId: _session.activeSurfaceId,
      surfaceHost: _session.surfaceHost,
      scrollController: _scrollController,
      textController: _textController,
      voiceController: _session.voiceController,
      isProcessing: _session.isProcessing,
      healthState: healthState,
      agentNames: agentNames,
      activeNodeName: 'Local Gateway',
      gatewayVersion: 'v2026.2.9',
      updateAvailable: false,
      remoteSessions: effectiveSessions,
      onSend: _send,
      onRetry: _session.retryLastMessage,
      onSelectAgent: (name) => _send('Show agent $name'),
      onQuickAction: _send,
    );
  }

  Widget _buildWatchLayout() {
    final agents = _session.agentStore.agents;
    final agentNames =
        agents.map((a) => a['name'] as String? ?? 'Untitled').toList();

    return WatchLayout(
      healthLevel: healthState.overall,
      activeAgentCount: agents.length,
      pendingApprovals: const [],
      agentNames: agentNames,
      onStartSpeaking: _toggleVoice,
      onApprove: (_) {},
      onDeny: (_) {},
      onPingAgent: (name) => _send('Check agent $name'),
    );
  }

  // ---------------------------------------------------------------------------
  // Pairing
  // ---------------------------------------------------------------------------

  void _showPairingModal(String pairingUrl) {
    ChatScreenDialogs.showPairingModal(
      context,
      pairingUrl: pairingUrl,
      session: _session,
      onHandlePairingLink: _handlePairingLink,
    );
  }

  void _handlePairingLink(String link) {
    try {
      final pairing = PlatformConfig.parsePairingUri(Uri.parse(link));
      if (pairing == null) return;

      _session.gatewayClient?.updateBaseUrl(pairing.url);
      if (pairing.token != null) {
        _session.gatewayClient?.updateToken(pairing.token!);
      }
      _session.setMode(SessionMode.home);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paired with gateway at ${pairing.url}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid pairing link: $e')));
    }
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

  Future<void> _send(String text) async {
    if (_session.isProcessing) return;
    HapticFeedback.lightImpact();
    await _session.sendMessage(
      text,
      onTranscriptionResult: (transcript, isFinal) {
        if (isFinal && transcript.isNotEmpty) {
          _send(transcript);
        }
      },
    );
  }

  void _toggleVoice() {
    final voice = _session.voiceController;
    if (voice == null) return;

    if (voice.isListening) {
      voice.stopListening();
      updateWatchListening(false);
    } else {
      updateWatchListening(true);
      voice.startListening(
        onResult: (transcript, isFinal) {
          if (isFinal && transcript.isNotEmpty) {
            updateWatchListening(false);
            _send(transcript);
          }
        },
      );
    }
  }

  void _toggleHandsFree() {
    setState(() => _handsFreeEnabled = !_handsFreeEnabled);
    final voice = _session.voiceController;
    if (voice == null) return;

    voice.continuousMode = _handsFreeEnabled;
    voice.setHandsFreeMode(
      enabled: _handsFreeEnabled,
      onCommand: (command, isFinal) {
        if (isFinal && command.isNotEmpty) {
          _send(command);
        }
      },
    );
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
    _session.onNavigateBack = null;
    _session.onPairingRequested = null;
    _session.removeListener(_onSessionChanged);
    disposeHealthMonitor();
    disposeWatchSync();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
