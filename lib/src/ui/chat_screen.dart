import 'dart:async';

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
import 'widgets/onboarding_modal.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatSession,
    this.sttService,
    this.onNavigateHome,
    this.showOnboarding = true,
  });

  final ChatSession chatSession;
  final SttService? sttService;
  final VoidCallback? onNavigateHome;
  final bool showOnboarding;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with HealthMonitorMixin, WatchSyncManager {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _screenFocusNode = FocusNode();
  final _inputFocusNode = FocusNode();
  final _inputKey = GlobalKey();

  ChatSession get _session => widget.chatSession;

  String? get _activeAgentName {
    final agents = _session.agentStore.agents;
    return agents.isNotEmpty ? agents.last['name'] as String? : null;
  }

  bool _handsFreeEnabled = false;
  bool _pendingGenUIScroll = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.showOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.8),
          builder: (context) => OnboardingModal(
            onFinish: () => Navigator.of(context).pop(),
          ),
        );
      });
    }

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
    // 檢查是否有新的 Surface 訊息（genUI），如果有則延遲滾動讓 UI 渲染完成
    final hasNewSurface = _session.messages.isNotEmpty &&
        _session.messages.last.isSurface;
    
    if (hasNewSurface && !_pendingGenUIScroll) {
      // 設定標誌避免重複觸發
      _pendingGenUIScroll = true;
      // 延遲 2 秒讓 genUI 完整渲染
      Future<void>.delayed(const Duration(seconds: 2), () {
        _scrollToBottom(smooth: true);
        _pendingGenUIScroll = false;
      });
    } else if (!hasNewSurface) {
      // 一般訊息立即滾動
      _scrollToBottom();
    }
    
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
        focusNode: _screenFocusNode,
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
                    ClawfreeIcons.iconForDeviceType(session.deviceType),
                    size: 14,
                    color: ClawfreeTheme.homeMode,
                  ),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 32),
              ],
            ),
          ),
        ),

        // -- Layer 3: Centered Logo/Title + Menu (Minimalist Ghost Header) --
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          height: 44,
          child: Container(
            color: Colors.transparent, // Ghost header
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 8,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(ClawfreeIcons.menuOpen, size: 22, color: ClawfreeTheme.hudTextPrimary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onNavigateHome,
                  borderRadius: ClawfreeBorderRadius.pill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: ClawfreeTheme.hudContainerColor,
                      borderRadius: ClawfreeBorderRadius.pill,
                      border: Border.all(color: ClawfreeTheme.hudBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_session.isProcessing)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        else
                          const Hero(tag: 'app-icon', child: ClawfreeLogo(size: 14)),
                        const SizedBox(width: 4),
                        Text(
                          (_activeAgentName ?? 'clawfree').toUpperCase(),
                          key: const Key('chat-title'),
                          style: ClawfreeTheme.technicalStyle(
                            context: context,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  child: IconButton(
                    icon: Icon(ClawfreeIcons.download, size: 22, color: ClawfreeTheme.hudTextPrimary),
                    onPressed: () => ChatScreenDialogs.showExportConfig(context, _session),
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
              Hero(tag: 'app-icon', child: ClawfreeLogo(size: 28)),
              const SizedBox(width: 8),
              Text(
                (_activeAgentName ?? 'clawfree').toUpperCase(),
                key: const Key('chat-title'),
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
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
          icon: Icon(ClawfreeIcons.download),
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
      key: const ValueKey('phone-layout'),
      inputKey: _inputKey,
      inputFocusNode: _inputFocusNode,
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
      inputKey: _inputKey,
      inputFocusNode: _inputFocusNode,
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
    unawaited(HapticFeedback.lightImpact());
    await _session.sendMessage(
      text,
      onTranscriptionResult: (transcript, isFinal) {
        if (isFinal && transcript.isNotEmpty) {
          unawaited(_send(transcript));
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

  void _scrollToBottom({bool smooth = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: smooth 
              ? const Duration(milliseconds: 1500)
              : const Duration(milliseconds: 300),
          curve: smooth ? Curves.easeInOut : Curves.easeOut,
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
    _screenFocusNode.dispose();
    _inputFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
