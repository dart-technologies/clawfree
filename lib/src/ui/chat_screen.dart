import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'watch_flow_overlay.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/chat_session.dart';
import '../core/health_poller.dart';
import '../core/input_coordinator.dart';
import '../core/platform_config.dart';
import '../core/prompt_library.dart';
import '../core/remote_session.dart';
import '../core/service_locator.dart';
import '../core/watch_bridge.dart';
import '../core/watch_sync_service.dart';
import '../devices/device_registry.dart';
import '../services/device_role.dart';
import '../services/local_sync_client.dart';
import '../services/local_sync_server.dart';
import '../services/openclaw_client.dart';
import '../voice/stt_service.dart';
import '../voice/tts_service.dart';
import '../voice/voice_controller.dart';
import 'settings/devices_page.dart';
import 'settings/watch_management_panel.dart';
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
  DeviceRegistry? _deviceRegistry;
  final _inputCoordinator = InputCoordinator();

  // Local sync for multi-device broadcast
  final _roleDetector = DeviceRoleDetector();
  LocalSyncServer? _syncServer;
  LocalSyncClient? _syncClient;

  /// Watch 互動流程的即時狀態（從 Watch 同步過來）
  Map<String, dynamic>? _watchUIState;
  StreamSubscription<SyncEvent>? _syncSub;

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
        inputCoordinator: _inputCoordinator,
      );
      _watchSync!.start();

      // Start polling immediately so vitals update as soon as possible.
      _healthPoller!.start();
    }

    // Initialize device registry for tracking connected devices.
    // Works with or without gateway — falls back to local-only mode.
    OpenClawClient? openClawClient;
    if (_session.gatewayClient != null) {
      openClawClient = OpenClawClient(
        baseUrl: _session.gatewayClient!.baseUrl,
      );
    }
    _deviceRegistry = DeviceRegistry(client: openClawClient);
    _deviceRegistry!.registerAndStart(
      deviceId: 'self-iphone',
      deviceName: 'iPhone',
      deviceType: 'phone',
    );

    // Initialize local sync based on device role
    _initLocalSync();

    // Listen to input coordinator for UI rebuilds
    _inputCoordinator.addListener(_onCoordinatorChanged);

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
    final gatewayUrl = _session.gatewayClient?.baseUrl;
    debugPrint('[ChatScreen] _initWatchBridge: gatewayUrl=$gatewayUrl');
    if (gatewayUrl != null) {
      WatchBridge.configure(gatewayUrl: gatewayUrl);
    }

    try {
      _watchSub = WatchBridge.onVoiceReceived.listen(
        (event) {
          debugPrint('[ChatScreen] Watch event received: type=${event.type} text="${event.text}" command="${event.command}" isTextCommand=${event.isTextCommand}');
          if (event.isUIState && event.uiState != null) {
            // Watch UI 狀態同步 → 廣播到 iPad/macOS + 更新本機顯示
            debugPrint('[ChatScreen] Watch UI state: ${event.uiState}');
            _syncServer?.broadcastRaw(event.uiState!);
            if (mounted) setState(() { _watchUIState = event.uiState; });
          } else if (event.isCommand && event.command != null) {
            // 結構化指令：plan_a_trip, create_agent → 帶參數同步 genUI
            debugPrint('[ChatScreen] Watch structured command: ${event.command} params=${event.params}');
            _handleWatchCommand(event.command!, params: event.params);
            WatchBridge.broadcastToRelay(event);
          } else if (event.isTranscribedText && event.text!.isNotEmpty) {
            // 手錶 Groq STT 轉錄文字 → 顯示在畫面上 + 送出
            debugPrint('[ChatScreen] Watch transcribed text: "${event.text}"');
            if (mounted) {
              setState(() {
                _textController.text = event.text!;
              });
            }
            _send(event.text!, source: InputSource.watch);
            WatchBridge.broadcastToRelay(event);
          } else if (event.isTextCommand && event.text!.isNotEmpty) {
            debugPrint('[ChatScreen] Forwarding Watch command to chat: "${event.text}"');
            // (a) Display in input field
            if (mounted) {
              setState(() {
                _textController.text = event.text!;
              });
            }
            // (b) Auto-send to ChatSession
            _send(event.text!, source: InputSource.watch);
            WatchBridge.broadcastToRelay(event);
          }
        },
        onError: (e) => debugPrint('[ChatScreen] Watch stream error: $e'),
        onDone: () => debugPrint('[ChatScreen] Watch stream closed'),
      );
      debugPrint('[ChatScreen] Watch bridge listener active');
    } catch (e) {
      debugPrint('[ChatScreen] Watch bridge not available: $e');
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

  void _onCoordinatorChanged() {
    if (mounted) setState(() {});
  }

  void _onSessionChanged() {
    _scrollToBottom();

    // Send AI text replies to Watch and sync devices
    if (_session.messages.isNotEmpty) {
      final last = _session.messages.last;
      if (!last.isUser && !last.isSurface && !_session.isProcessing && last.text != null) {
        WatchBridge.sendReplyToWatch(last.text!).catchError((_) => null);
        _syncServer?.broadcastAiResponse(last.text!);
      }
    }

    // Track pipeline completion for queued input auto-replay
    if (!_session.isProcessing &&
        _inputCoordinator.state != PipelineState.idle) {
      final queued = _inputCoordinator.markComplete();
      if (queued != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _send(queued.$2, source: queued.$1);
        });
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
        if (_syncDeviceCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Chip(
              avatar: const Icon(Icons.devices, size: 16),
              label: Text('$_syncDeviceCount'),
              visualDensity: VisualDensity.compact,
            ),
          ),
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

    Widget layout;
    switch (formFactor) {
      case DeviceFormFactor.phone:
        layout = _buildPhoneLayout();
      case DeviceFormFactor.tablet:
      case DeviceFormFactor.desktop:
        layout = _buildTabletLayout(context);
      case DeviceFormFactor.watch:
        layout = _buildWatchLayout();
    }

    // Watch UI 狀態同步覆蓋層
    if (_watchUIState != null) {
      return Stack(
        children: [
          layout,
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: WatchFlowOverlay(state: _watchUIState!),
              ),
            ),
          ),
        ],
      );
    }
    return layout;
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
      onViewDevices: _navigateToDevices,
      onManageWatch: _showWatchManagementPanel,
      activeInputSource: _inputCoordinator.activeSource,
      queuedInputSource: _inputCoordinator.queuedSource,
      watchConnectionState: _deviceRegistry?.watchState.connectionState,
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
  // Devices
  // ---------------------------------------------------------------------------

  void _showWatchManagementPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => WatchManagementPanel(registry: _deviceRegistry!),
    );
  }

  void _navigateToDevices() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DevicesPage(registry: _deviceRegistry!),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Local Sync
  // ---------------------------------------------------------------------------

  void _initLocalSync() {
    // Defer role detection until after first frame (needs MediaQuery).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = _roleDetector.detect(context);
      debugPrint('[ChatScreen] Device sync role: $role');
      if (role == SyncRole.host) {
        _syncServer = LocalSyncServer();
        _syncServer!.addListener(() {
          if (mounted) setState(() {});
        });
        _syncServer!.start();
        // 監聽從 client 裝置傳來的訊息
        _syncServer!.incomingMessages.listen((msg) {
          if (!mounted) return;
          final type = msg['type'] as String? ?? '';
          final text = msg['text'] as String? ?? '';
          if (type == 'user_message' && text.isNotEmpty) {
            _session.sendMessage(text);
          }
        });
      } else {
        // Client 模式 — 嘗試連線到 host
        final ip = _roleDetector.hostIp ?? '127.0.0.1';
        _startSyncClient(ip);
      }
    });
  }

  void _startSyncClient(String hostIp) {
    _syncClient = LocalSyncClient(serverUrl: 'ws://$hostIp:8765');
    _syncClient!.addListener(() {
      if (mounted) setState(() {});
    });
    _syncSub = _syncClient!.events.listen((event) {
      if (event.type == 'user_message') {
        _session.sendMessage(event.text);
      } else if (event.type == 'ui_state') {
        // Watch UI 狀態從 server 同步過來
        if (mounted) setState(() { _watchUIState = event.data; });
      }
      // ai_response events update via the normal ChatSession flow
    });
    _syncClient!.connect();
  }

  /// Number of connected sync devices (for UI badge).
  int get _syncDeviceCount {
    if (_syncServer != null) return _syncServer!.clientCount;
    if (_syncClient != null && _syncClient!.isConnected) return 1;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// 手錶 → iPhone 選項對照表（手錶簡稱 → genUI 全名）
  static const _cityMapping = {
    'Tokyo': 'Tokyo, Japan',
    'Kyoto': 'Kyoto, Japan',
    'Osaka': 'Osaka, Japan',
    'Seoul': 'Seoul, South Korea',
    'Bangkok': 'Bangkok, Thailand',
    'Paris': 'Paris, France',
    'New York': 'New York, USA',
    'London': 'London, UK',
  };

  static const _modelMapping = {
    'Opus 4.6': 'Claude Opus 4.6',
    'Sonnet 4.5': 'Claude Sonnet 4.5',
    'Gemini Pro': 'Gemini Pro',
    'GPT-4': 'GPT-4 Turbo',
  };

  /// 處理手錶結構化指令 — 帶參數同步 genUI 選項
  void _handleWatchCommand(String command, {Map<String, dynamic>? params}) {
    debugPrint('[ChatScreen] Watch command: $command params=$params');

    switch (command) {
      case 'plan_a_trip':
        final city = params?['city'] as String? ?? '';
        final days = params?['days'] as int? ?? 3;
        final attractions = (params?['attractions'] as List?)?.cast<String>() ?? [];
        final mappedCity = _cityMapping[city] ?? city;

        // 同步 Watch UI 狀態到 genUI overlay
        if (mounted) {
          setState(() {
            _watchUIState = {
              'flow': 'tripPlanner',
              'step': 3,  // 確認步驟
              'selectedCity': city,
              'selectedDays': days,
              'selectedAttractions': attractions,
              'mappedCity': mappedCity,
              'source': 'watch_command',
            };
          });
        }

        final attractionStr = attractions.isNotEmpty ? ' including ${attractions.join(', ')}' : '';
        _send('Plan a $days day trip to $mappedCity$attractionStr', source: InputSource.watch);
        break;

      case 'create_agent':
        final model = params?['model'] as String? ?? '';
        final name = params?['name'] as String? ?? 'Agent';
        final skills = (params?['skills'] as List?)?.cast<String>() ?? [];
        final mappedModel = _modelMapping[model] ?? model;

        // 同步 Watch UI 狀態到 genUI overlay
        if (mounted) {
          setState(() {
            _watchUIState = {
              'flow': 'agentConfig',
              'step': 2,  // 確認步驟
              'selectedModel': model,
              'selectedSkills': skills,
              'mappedModel': mappedModel,
              'agentName': name,
              'source': 'watch_command',
            };
          });
        }

        final skillStr = skills.isNotEmpty ? ' and skills: ${skills.join(', ')}' : '';
        _send('Create a $name with $mappedModel$skillStr', source: InputSource.watch);
        break;

      default:
        debugPrint('[ChatScreen] Unknown watch command: $command');
        _send(command, source: InputSource.watch);
    }
  }

  void _sendFromTextField() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _send(text);
  }

  void _send(String text, {InputSource source = InputSource.phone}) {
    HapticFeedback.lightImpact();
    final immediate = _inputCoordinator.submit(source, text);
    if (immediate != null) {
      _session.sendMessage(immediate);
      // Broadcast to connected sync devices
      final srcName = source == InputSource.watch
          ? 'watch'
          : source == InputSource.phone
              ? 'voice'
              : 'keyboard';
      _syncServer?.broadcastUserMessage(immediate, source: srcName);
      // Client 模式：傳送訊息到 server 轉發給其他裝置
      _syncClient?.sendUserMessage(immediate, source: srcName);
    }
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

  Future<void> _startListening() async {
    // Don't start phone recording if watch is active
    if (!_inputCoordinator.requestAccess(InputSource.phone)) return;

    // Check STT availability before updating UI state
    final stt = widget.sttService;
    if (stt != null && !await stt.isAvailable) {
      debugPrint('[ChatScreen] STT not available (permission denied or unsupported)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition unavailable. Check microphone permissions in Settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final vc = sl.tryGet<VoiceController>();
    if (vc != null) {
      setState(() {
        _isListening = true;
        _interimTranscript = '';
      });
      _watchSync?.updateListening(true);
      vc.startListening(onResult: _onSttResult);
    } else if (stt != null) {
      setState(() {
        _isListening = true;
        _interimTranscript = '';
      });
      _watchSync?.updateListening(true);
      stt.startListening(onResult: _onSttResult);
    } else {
      debugPrint('[ChatScreen] No STT service available');
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
    _inputCoordinator.removeListener(_onCoordinatorChanged);
    _inputCoordinator.dispose();
    _healthPoller?.removeListener(_onHealthChanged);
    _healthPoller?.dispose();
    _watchSync?.stop();
    _deviceRegistry?.dispose();
    _ttsPollTimer?.cancel();
    _watchSub?.cancel();
    _syncSub?.cancel();
    _syncServer?.dispose();
    _syncClient?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
