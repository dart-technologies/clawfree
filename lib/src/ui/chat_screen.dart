import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/chat_session.dart';
import '../core/health_poller.dart';
import '../core/platform_config.dart';
import '../core/prompt_library.dart';
import '../core/remote_session.dart';
import '../core/service_locator.dart';
import '../core/watch_bridge.dart';
import '../core/watch_sync_service.dart';
import '../voice/stt_service.dart';
import '../voice/tts_service.dart';
import '../voice/voice_controller.dart';
import 'widgets/qr_scanner_dialog.dart';
import 'clawfree_assets.dart';
import 'clawfree_icons.dart';
import 'health/health_indicators.dart';
import 'layouts/phone_layout.dart';
import 'layouts/tablet_layout.dart';
import 'layouts/watch_layout.dart';

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

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  ChatSession get _session => widget.chatSession;

  // Voice state for phone layout
  bool _isListening = false;
  bool _isSpeaking = false;
  String _interimTranscript = '';
  bool _handsFreeEnabled = false;

  // TTS polling timer for speaking state
  Timer? _ttsPollTimer;
  StreamSubscription<WatchVoiceEvent>? _watchSub;

  // Health state — optimistic nominal default so vitals show green immediately.
  // The HealthPoller overrides with live data when the REST endpoint is available.
  HealthState _healthState = HealthState.nominal();
  HealthPoller? _healthPoller;
  List<RemoteSession> _remoteSessions = [];

  WatchSyncService? _watchSync;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _session.onPairingRequested = _showPairingModal;
    _session.onNavigateBack = () => widget.onNavigateHome?.call();

    if (_session.gatewayClient != null) {
      _healthPoller = HealthPoller(gatewayClient: _session.gatewayClient!);
      _healthPoller!.addListener(_onHealthChanged);
      
      _watchSync = WatchSyncService(
        healthPoller: _healthPoller!,
        agentStore: _session.agentStore,
      );
      _watchSync!.start();

      // Start polling immediately so vitals update as soon as possible.
      _healthPoller!.start();
    }

    // Poll TTS speaking state to drive VoiceOrb animation
    _ttsPollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final tts = sl.tryGet<TtsService>();
      if (tts != null && mounted) {
        final speaking = tts.isSpeaking;
        if (speaking != _isSpeaking) {
          setState(() => _isSpeaking = speaking);
          // Auto-restart listening after TTS finishes in hands-free mode
          if (!speaking && _handsFreeEnabled && !_isListening) {
            _startListening();
          }
        }
      }
    });

    // Listen for Watch voice events
    _initWatchBridge();
  }

  void _initWatchBridge() {
    try {
      _watchSub = WatchBridge.onVoiceReceived.listen((event) {
        if (event.isTextCommand && event.text!.isNotEmpty) {
          // Watch sent recognized text — feed directly into chat
          _send(event.text!);
        }
        // File-based events could be transcribed here in the future
      });
    } catch (_) {
      // Watch bridge not available on this platform
    }
  }

  void _onHealthChanged() {
    if (mounted) {
      setState(() {
        _healthState = _healthPoller!.state;
        _remoteSessions = _healthPoller!.sessions;
      });
    }
  }

  void _onSessionChanged() {
    _scrollToBottom();

    // Send AI text replies to Watch if connected
    if (_session.messages.isNotEmpty) {
      final last = _session.messages.last;
      if (!last.isUser && !last.isSurface && !_session.isProcessing && last.text != null) {
        WatchBridge.sendReplyToWatch(last.text!).catchError((_) => null);
      }
    }

    // Ensure widget rebuilds for session state changes.
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
          listenable: _session,
          builder: (context, _) {
            return Scaffold(
              appBar: _buildAppBar(context),
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
  // App bar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
            child:
                Image.asset(ClawfreeAssets.icon, width: 28, height: 28),
          ),
          const SizedBox(width: 8),
          const Text('clawfree'),
          if (_session.sessionMode == SessionMode.home) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Home',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
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
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ),
        _buildExportButton(),
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
        return _buildPhoneLayout();
      case DeviceFormFactor.tablet:
      case DeviceFormFactor.desktop:
        return _buildTabletLayout(context);
      case DeviceFormFactor.watch:
        return _buildWatchLayout();
    }
  }

  // ---------------------------------------------------------------------------
  // Phone: "The Mobile Remote"
  // ---------------------------------------------------------------------------

  Widget _buildPhoneLayout() {
    final isHome = _session.sessionMode == SessionMode.home;
    final agents = _session.agentStore.agents;
    final activeAgent =
        agents.isNotEmpty ? agents.last['name'] as String? : null;

    final effectiveSessions = _remoteSessions.isNotEmpty
        ? _remoteSessions
        : (_session.gatewayClient == null
            ? defaultDemoSessions(DeviceFormFactor.phone)
            : <RemoteSession>[]);

    return PhoneLayout(
      sessionMode: _session.sessionMode,
      messages: _session.messages,
      activeSurfaceId: _session.activeSurfaceId,
      surfaceHost: _session.surfaceHost,
      scrollController: _scrollController,
      textController: _textController,
      sttService: widget.sttService,
      isProcessing: _session.isProcessing,
      healthState: _healthState,
      isListening: _isListening,
      isSpeaking: _isSpeaking,
      interimTranscript: _interimTranscript,
      isHomeDashboard: isHome,
      activeAgentName: activeAgent,
      handsFreeEnabled: _handsFreeEnabled,
      remoteSessions: effectiveSessions,
      onSend: _send,
      onRetry: _session.retryLastMessage,
      onToggleVoice: _toggleVoice,
      onToggleHandsFree: _toggleHandsFree,
      onQuickAction: _send,
      onPairDevice: () => _showPairingModal(_session.pairingUrl),
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet/Desktop: "The Control Tower"
  // ---------------------------------------------------------------------------

  Widget _buildTabletLayout(BuildContext context) {
    final agents = _session.agentStore.agents;
    final agentNames =
        agents.map((a) => a['name'] as String? ?? 'Untitled').toList();

    final effectiveSessions = _remoteSessions.isNotEmpty
        ? _remoteSessions
        : (_session.gatewayClient == null
            ? defaultDemoSessions(DeviceFormFactor.tablet)
            : <RemoteSession>[]);

    return TabletLayout(
      messages: _session.messages,
      activeSurfaceId: _session.activeSurfaceId,
      surfaceHost: _session.surfaceHost,
      scrollController: _scrollController,
      textController: _textController,
      sttService: widget.sttService,
      isProcessing: _session.isProcessing,
      healthState: _healthState,
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

  // ---------------------------------------------------------------------------
  // Watch: "The Pulse Monitor"
  // ---------------------------------------------------------------------------

  Widget _buildWatchLayout() {
    final agents = _session.agentStore.agents;
    final agentNames =
        agents.map((a) => a['name'] as String? ?? 'Untitled').toList();

    return WatchLayout(
      healthLevel: _healthState.overall,
      activeAgentCount: agents.length,
      pendingApprovals: const [], // populated by system_run events
      agentNames: agentNames,
      onStartSpeaking: _toggleVoice,
      onApprove: (_) {},
      onDeny: (_) {},
      onPingAgent: (name) => _send('Check agent $name'),
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
        HapticFeedback.lightImpact();
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
  // QR Pairing Modal
  // ---------------------------------------------------------------------------

  void _showPairingModal(String pairingUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        // Use up to 90% of screen width, capped at 400.
        final screenWidth = MediaQuery.sizeOf(ctx).width;
        final qrSize = (screenWidth * 0.65).clamp(200.0, 320.0);

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.qr_code_2,
                  color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Pair a Device'),
            ],
          ),
          content: SizedBox(
            width: qrSize + 40,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: pairingUrl,
                    version: QrVersions.auto,
                    size: qrSize,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: Color(0xFF1A1A2E),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  pairingUrl,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan with your iPhone or Apple Watch to pair.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            ),
          ),
          actions: [
            if (PlatformConfig.hasCamera)
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const QrScannerDialog()),
                  );
                  if (result != null && ctx.mounted) {
                    _handlePairingLink(result);
                    Navigator.pop(ctx);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pairingUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pairing link copied')),
                );
              },
              icon: const Icon(ClawfreeIcons.copy, size: 16),
              label: const Text('Copy Link'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid pairing link: $e')),
      );
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

  void _send(String text) {
    HapticFeedback.lightImpact();
    _session.sendMessage(text);
  }

  void _toggleVoice() {
    // If TTS is speaking, stop it first
    final tts = sl.tryGet<TtsService>();
    if (_isSpeaking && tts != null) {
      tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    if (_isListening) {
      _stopListening(sendTranscript: true);
    } else {
      _startListening();
    }
  }

  void _startListening() {
    final vc = sl.tryGet<VoiceController>();
    if (vc != null) {
      setState(() {
        _isListening = true;
        _interimTranscript = '';
      });
      _watchSync?.updateListening(true);
      vc.startListening(onResult: _onSttResult);
    } else {
      // Fallback to raw SttService
      setState(() {
        _isListening = true;
        _interimTranscript = '';
      });
      _watchSync?.updateListening(true);
      widget.sttService?.startListening(onResult: _onSttResult);
    }
  }

  void _stopListening({bool sendTranscript = false}) {
    final vc = sl.tryGet<VoiceController>();
    if (vc != null) {
      vc.stopListening();
    } else {
      widget.sttService?.stopListening();
    }
    _watchSync?.updateListening(false);
    setState(() {
      _isListening = false;
      if (sendTranscript && _interimTranscript.isNotEmpty) {
        _send(_interimTranscript);
      }
      _interimTranscript = '';
    });
  }

  void _onSttResult(String transcript, bool isFinal) {
    if (!mounted) return;
    setState(() => _interimTranscript = transcript);
    if (isFinal && transcript.isNotEmpty) {
      _stopListening();
      _send(transcript);
    }
  }

  void _toggleHandsFree() {
    final newValue = !_handsFreeEnabled;
    setState(() => _handsFreeEnabled = newValue);

    final vc = sl.tryGet<VoiceController>();
    if (vc != null) {
      vc.setHandsFreeMode(
        enabled: newValue,
        onCommand: newValue ? _onSttResult : null,
      );
    }
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
    _healthPoller?.removeListener(_onHealthChanged);
    _healthPoller?.dispose();
    _watchSync?.stop();
    _ttsPollTimer?.cancel();
    _watchSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
