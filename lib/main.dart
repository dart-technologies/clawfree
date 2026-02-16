import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/agent_store.dart';
import 'src/core/ai_client.dart';
import 'src/core/chat_session.dart';
import 'src/core/demo_ai_client.dart';
import 'src/core/gateway_client.dart';

import 'src/core/demo_sync_client.dart';
import 'src/core/local_network.dart';
import 'src/core/platform_config.dart';
import 'src/core/prompt_library.dart';
import 'src/core/service_locator.dart';
import 'src/core/shared_preferences_agent_store.dart';
import 'src/ui/chat_screen.dart';
import 'src/ui/clawfree_assets.dart';
import 'src/ui/theme.dart';
import 'src/ui/widgets/qr_scanner_dialog.dart';
import 'src/voice/earcon_service.dart';
import 'src/voice/stt_service.dart';
import 'src/voice/tts_service.dart';
import 'src/voice/voice_controller.dart';
import 'src/voice/voice_service_factory.dart';

/// Compile-time constants from --dart-define
const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
const _gatewayUrl = String.fromEnvironment('GATEWAY_URL', defaultValue: '');
const _demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
const _demoScenario = String.fromEnvironment('DEMO_SCENARIO', defaultValue: '');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary: show a friendly card instead of red screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 32),
            const SizedBox(height: 8),
            Text(
              'Something went wrong rendering this UI.',
              style: TextStyle(color: Colors.red.shade800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  };

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const ClawfreeApp());
}

class ClawfreeApp extends StatelessWidget {
  const ClawfreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'clawfree',
      debugShowCheckedModeBanner: false, // 移除 debug banner
      theme: ClawfreeTheme.light,
      darkTheme: ClawfreeTheme.dark,
      themeMode: ThemeMode.dark, // Force dark mode for HUD-first experience
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOut,
      home: const ClawfreeHome(),
    );
  }
}

class ClawfreeHome extends StatefulWidget {
  const ClawfreeHome({super.key});

  @override
  State<ClawfreeHome> createState() => _ClawfreeHomeState();
}

class _ClawfreeHomeState extends State<ClawfreeHome> {
  ChatSession? _chatSession;
  SttService? _sttService;
  DemoSyncClient? _syncClient;
  StreamSubscription<DemoSyncMessage>? _syncSubscription;
  StreamSubscription<GenUITriggerAction>? _triggerSubscription;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final _apiKeyController = TextEditingController(text: _apiKey);
  bool _useDemoMode = _demoMode;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    // Auto-trigger for demo mode if a scenario is specified.
    if (_useDemoMode && _demoScenario.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _start();
      });
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    // Handle cold-start deep link (app launched via URL).
    _appLinks.getInitialLink().then((uri) {
      if (uri != null && uri.scheme == 'clawfree' && uri.host == 'pair') {
        _handleDeepLink(uri);
      }
    });
    // Handle warm-start deep links (app already running).
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'clawfree' && uri.host == 'pair') {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    final pairing = PlatformConfig.parsePairingUri(uri);
    if (pairing == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Received pairing link for ${pairing.url}')),
    );
    if (_chatSession != null) {
      _chatSession!.gatewayClient?.updateBaseUrl(pairing.url);
      if (pairing.token != null) {
        _chatSession!.gatewayClient?.updateToken(pairing.token!);
      }
      _chatSession!.setMode(SessionMode.home);
    } else {
      _start(injectedGateway: pairing.url, injectedToken: pairing.token);
    }
  }

  Future<void> _start({String? injectedGateway, String? injectedToken}) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty &&
        !PlatformConfig.isWeb &&
        !_useDemoMode &&
        injectedGateway == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Anthropic API key')),
      );
      return;
    }

    final effectiveUrl =
        injectedGateway ??
        PlatformConfig.resolveBaseUrl(gatewayUrl: _gatewayUrl);
    final effectiveToken =
        injectedToken ??
        const String.fromEnvironment('GATEWAY_TOKEN', defaultValue: '');

    final AiClient aiClient;
    if (_useDemoMode) {
      aiClient = DemoCacheAiClient();
    } else {
      aiClient = AnthropicAiClient(apiKey: key, baseUrl: effectiveUrl);
    }

    // Parallelize independent async init work.
    final earconService = EarconService();
    final agentStoreFuture = _useDemoMode
        ? Future.value(AgentStore() as AgentRepository)
        : SharedPreferencesAgentStore.create();
    final earconFuture = earconService.init();

    GatewayClient? gatewayClient;
    if (!_useDemoMode) {
      gatewayClient = GatewayClient(
        baseUrl: effectiveUrl,
        token: effectiveToken,
      );
    }

    final voice = VoiceServiceFactory.create(
      isDemo: _useDemoMode,
      forceRealTts: _demoScenario == 'travel',
    );

    // Await both in parallel.
    final prefsFuture = SharedPreferences.getInstance();
    final results = await Future.wait([agentStoreFuture, earconFuture, prefsFuture]);
    final agentStore = results[0] as AgentRepository;
    final prefs = results[2] as SharedPreferences;

    sl.reset();
    sl.register<AiClient>(aiClient);
    if (gatewayClient != null) {
      sl.register<GatewayClient>(gatewayClient);
    }
    sl.register<TtsService>(voice.tts);
    sl.register<SttService>(voice.stt);
    sl.register<EarconService>(earconService);
    sl.register<VoiceController>(
      VoiceController(stt: voice.stt, tts: voice.tts, earcon: earconService),
    );

    _chatSession = ChatSession(
      aiClient: sl.get<AiClient>(),
      voiceController: sl.tryGet<VoiceController>(),
      agentStore: agentStore,
      gatewayClient: gatewayClient,
    );

    // Resolve LAN IP for scannable QR codes (non-blocking).
    if (injectedGateway == null) {
      unawaited(getLocalIpAddress().then((localIp) {
        _chatSession?.pairingUrl = 'http://$localIp:18789/pair';
      }));
    } else {
      _chatSession?.setMode(SessionMode.home);
    }

    _sttService = sl.tryGet<SttService>();

    // Demo 模式：連線到本地同步伺服器，接收 Watch 訊息
    if (_useDemoMode) {
      _syncClient = DemoSyncClient();
      unawaited(_syncClient!.connect());
      // Hot Reload 時先取消舊訂閱，避免重複
      _syncSubscription?.cancel();
      _syncSubscription = _syncClient!.onMessage.listen((msg) {
        if (msg.isUser && _chatSession != null) {
          // 收到 Watch 的使用者訊息，送入 ChatSession 處理（會觸發 AI 回覆 + genUI）
          debugPrint('[DemoSync] 轉發使用者訊息到 ChatSession: "${msg.text}"');
          unawaited(_chatSession!.sendMessage(msg.text));
        }
      });

      // 監聽 genUI 觸發事件：Watch 關鍵字 → 模擬 Surface 互動推進 genUI 狀態
      // Hot Reload 時先取消舊訂閱，避免重複
      _triggerSubscription?.cancel();
      _triggerSubscription = _syncClient!.onGenUITrigger.listen((action) {
        if (_chatSession == null) return;
        debugPrint('[DemoSync] 🎯 處理 genUI 觸發: $action');
        final interaction = _buildTriggerInteraction(action);
        if (interaction != null) {
          // 延遲執行，確保 sendMessage 的 AI 回覆先完成
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (_chatSession != null) {
              _chatSession!.simulateSurfaceInteraction(interaction);
            }
          });
        }
      });
    }

    if (_useDemoMode && _demoScenario == 'travel') {
      unawaited(_runDemoAutomation());
    }

    final showOnboarding = !(prefs.getBool('has_seen_onboarding') ?? false);
    if (showOnboarding) {
      unawaited(prefs.setBool('has_seen_onboarding', true));
    }

    if (!mounted) return;
    unawaited(Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatSession: _chatSession!,
              sttService: _sttService,
              onNavigateHome: () => Navigator.of(context).pop(),
              showOnboarding: showOnboarding,
            ),
          ),
        )
        .then((_) {
          _chatSession?.dispose();
          _chatSession = null;
          _sttService?.dispose();
          _sttService = null;
          sl.tryGet<GatewayClient>()?.dispose();
          sl.reset();
        }));
  }

  /// 根據 genUI 觸發動作建構對應的 Surface 互動事件
  ChatMessage? _buildTriggerInteraction(GenUITriggerAction action) {
    switch (action) {
      case GenUITriggerAction.createAgent:
        // "Plan a 3-day trip" → 顯示 Create Agent UI（不需要互動事件）
        return null;
      case GenUITriggerAction.planTrip:
        return ChatMessage(
          role: ChatMessageRole.user,
          parts: [
            TextPart(
              jsonEncode({
                'action': {
                  'name': 'save_agent',
                  'context': {
                    'name': 'Travel Concierge',
                    'model': ['claude-opus-4-6'],
                    'tools': ['browser', 'code', 'search', 'api'],
                    'channels': ['telegram', 'slack', 'discord'],
                  },
                },
              }),
            ),
          ],
        );
      case GenUITriggerAction.generateItinerary:
        return ChatMessage(
          role: ChatMessageRole.user,
          parts: [
            TextPart(
              jsonEncode({
                'action': {
                  'name': 'generate_itinerary',
                  'context': {
                    'city': ['tokyo'],
                    'vibe': ['foodie'],
                    'days': ['3'],
                  },
                },
              }),
            ),
          ],
        );
      case GenUITriggerAction.bookTrip:
        return ChatMessage(
          role: ChatMessageRole.user,
          parts: [
            TextPart(
              jsonEncode({
                'action': {
                  'name': 'book_trip',
                  'context': {
                    'city': 'tokyo',
                    'days': 3,
                    'vibe': 'foodie',
                    'flight': 'ANA',
                  },
                },
              }),
            ),
          ],
        );
    }
  }

  /// Runs the full "Tokyo Travel" demo workflow automatically.
  /// 1. Create Agent command
  /// 2. Wait for form, click Save Agent (simulated)
  /// 3. Plan Trip command
  /// 4. Generate Itinerary (simulated)
  /// 5. Book Trip (simulated)
  Future<void> _runDemoAutomation() async {
    final session = _chatSession;
    if (session == null) return;

    // Step 1: Create Agent
    await Future<void>.delayed(const Duration(seconds: 2));
    await session.sendVoiceCommand(
      'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
    );

    // Step 2: Save Agent interaction
    await Future<void>.delayed(const Duration(seconds: 4));
    session.simulateSurfaceInteraction(
      ChatMessage(
        role: ChatMessageRole.user,
        parts: [
          TextPart(
            jsonEncode({
              'action': {
                'name': 'save_agent',
                'context': {
                  'name': 'Travel Concierge',
                  'model': ['claude-opus-4-6'],
                  'tools': ['browser', 'code', 'search', 'api'],
                  'channels': ['telegram', 'slack', 'discord'],
                },
              },
            }),
          ),
        ],
      ),
    );

    // Step 3: Plan Trip is auto-triggered by save_agent → userInput("Plan a trip")
    // Wait for the travel setup genUI to render.

    // Step 4: Generate Itinerary interaction
    await Future<void>.delayed(const Duration(seconds: 7));
    // For generate_itinerary, we simulate interaction AND handle the result text manually
    // because simulation triggers side effects but doesn't return the result synchronously here.
    // Actually, simulation triggers _performGeneration if it's UserInputResult.
    // Let's rely on that!
    session.simulateSurfaceInteraction(
      ChatMessage(
        role: ChatMessageRole.user,
        parts: [
          TextPart(
            jsonEncode({
              'action': {
                'name': 'generate_itinerary',
                'context': {
                  'city': ['tokyo'],
                  'vibe': ['foodie'],
                  'days': ['3'],
                },
              },
            }),
          ),
        ],
      ),
    );

    // Removed manual sendMessage since simulateSurfaceInteraction handles UserInputResult.

    // Step 5: Book Trip interaction
    await Future<void>.delayed(const Duration(seconds: 6));
    await Future<void>.delayed(const Duration(seconds: 6));
    session.simulateSurfaceInteraction(
      ChatMessage(
        role: ChatMessageRole.user,
        parts: [
          TextPart(
            jsonEncode({
              'action': {
                'name': 'book_trip',
                'context': {
                  'city': 'tokyo',
                  'days': 3,
                  'vibe': 'foodie',
                  'flight': 'ANA',
                },
              },
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = PlatformConfig.isWeb;
    final formFactor = PlatformConfig.formFactor(context);
    final isLarge =
        formFactor == DeviceFormFactor.tablet ||
        formFactor == DeviceFormFactor.desktop;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isLarge ? 64 : 32),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLarge ? 600 : 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'app-icon',
                    child: ClawfreeLogo(size: isLarge ? 240 : 160),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'CLAWFREE',
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: isLarge ? 48 : 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HANDS-FREE AI AGENTIC ORCHESTRATOR',
                    textAlign: TextAlign.center,
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: isLarge ? 16 : 12,
                      color: ClawfreeTheme.hudTextSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (!isWeb && !_useDemoMode)
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'ANTHROPIC API KEY',
                        hintText: 'sk-ant-...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _start(),
                    ),
                  if (isWeb && !_useDemoMode)
                    Text(
                      'GATEWAY: ${PlatformConfig.resolveBaseUrl(gatewayUrl: _gatewayUrl)}',
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 12,
                        color: ClawfreeTheme.hudTextMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  if (_useDemoMode)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ClawfreeTheme.hudActive.withValues(alpha: 0.08),
                        borderRadius: ClawfreeBorderRadius.interactive,
                        border: Border.all(
                          color: ClawfreeTheme.hudActive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle,
                            size: 28,
                            color: ClawfreeTheme.hudActive,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'DEMO MODE: CACHED RESPONSES (NO API KEY)',
                              style: ClawfreeTheme.technicalStyle(
                                context: context,
                                fontSize: 12,
                                color: ClawfreeTheme.hudActive,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              _useDemoMode ? 'START DEMO' : 'START',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!_useDemoMode && PlatformConfig.hasCamera) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          width: 56,
                          child: IconButton.filledTonal(
                            onPressed: () async {
                              final result = await Navigator.of(context)
                                  .push<String>(
                                    MaterialPageRoute(
                                      builder: (_) => const QrScannerDialog(),
                                    ),
                                  );
                              if (result != null && mounted) {
                                unawaited(_handleQrResult(result));
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Scan Gateway QR',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DEMO MODE',
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: 12,
                          color: ClawfreeTheme.hudTextMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch.adaptive(
                        value: _useDemoMode,
                        onChanged: (v) => setState(() => _useDemoMode = v),
                      ),
                    ],
                  ),
                  if (!isWeb && !_useDemoMode) ...[
                    const SizedBox(height: 12),
                    Text(
                      '--dart-define=ANTHROPIC_API_KEY=sk-ant-...',
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 11,
                        color: ClawfreeTheme.hudTextFaint,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleQrResult(String data) async {
    try {
      final uri = Uri.parse(data);
      final pairing = PlatformConfig.parsePairingUri(uri);
      if (pairing == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unrecognized QR code format')),
        );
        return;
      }
      // Deep links carry a pre-validated gateway URL + token.
      if (uri.scheme == 'clawfree') {
        _handleDeepLink(uri);
        return;
      }
      // Raw HTTP URL — validate that it's a clawfree gateway.
      if (!await _validateGateway(pairing.url)) return;
      unawaited(_start(injectedGateway: pairing.url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid QR: $e')));
    }
  }

  /// Probes [url]/health and confirms the response contains the expected
  /// service identifier. Returns false (with user feedback) on failure.
  Future<bool> _validateGateway(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['service'] == 'clawfree-gateway') return true;
      }
    } catch (_) {
      // fall through to error below
    }
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not verify clawfree gateway at $url')),
    );
    return false;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _syncSubscription?.cancel();
    _triggerSubscription?.cancel();
    _syncClient?.dispose();
    _chatSession?.dispose();
    _sttService?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
