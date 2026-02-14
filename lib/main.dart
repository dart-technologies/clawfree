import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'src/core/agent_store.dart';
import 'src/core/ai_client.dart';
import 'src/core/chat_session.dart';
import 'src/core/demo_ai_client.dart';
import 'src/core/gateway_client.dart';
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
      theme: ClawfreeTheme.light,
      darkTheme: ClawfreeTheme.dark,
      themeMode: ThemeMode.dark,
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
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final _apiKeyController = TextEditingController(text: _apiKey);
  bool _useDemoMode = _demoMode;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
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
    if (key.isEmpty && !PlatformConfig.isWeb && !_useDemoMode && injectedGateway == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Anthropic API key')),
      );
      return;
    }

    final effectiveUrl = injectedGateway ??
        PlatformConfig.resolveBaseUrl(gatewayUrl: _gatewayUrl);
    final effectiveToken = injectedToken ??
        const String.fromEnvironment('GATEWAY_TOKEN', defaultValue: '');

    final AiClient aiClient;
    if (_useDemoMode) {
      aiClient = DemoCacheAiClient();
    } else {
      aiClient = AnthropicAiClient(
        apiKey: key,
        baseUrl: effectiveUrl,
      );
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

    final voice = VoiceServiceFactory.create(isDemo: _useDemoMode);

    // Await both in parallel.
    final results = await Future.wait([agentStoreFuture, earconFuture]);
    final agentStore = results[0] as AgentRepository;

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
      ttsService: sl.tryGet<TtsService>(),
      agentStore: agentStore,
      gatewayClient: gatewayClient,
    );

    // Resolve LAN IP for scannable QR codes (non-blocking).
    if (injectedGateway == null) {
      getLocalIpAddress().then((localIp) {
        _chatSession?.pairingUrl = 'http://$localIp:18789/pair';
      });
    } else {
      _chatSession?.setMode(SessionMode.home);
    }

    _sttService = sl.tryGet<SttService>();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatSession: _chatSession!,
          sttService: _sttService,
          onNavigateHome: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      _chatSession?.dispose();
      _chatSession = null;
      _sttService?.dispose();
      _sttService = null;
      sl.tryGet<GatewayClient>()?.dispose();
      sl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = PlatformConfig.isWeb;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.85 + 0.15 * value,
                child: child,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'app-icon',
                    child: Image.asset(
                      ClawfreeAssets.icon,
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'clawfree',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hands-free AI agent creation',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!isWeb && !_useDemoMode)
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Anthropic API Key',
                        hintText: 'sk-ant-...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _start(),
                    ),
                  if (isWeb && !_useDemoMode)
                    Text(
                      'Using gateway at ${PlatformConfig.resolveBaseUrl(gatewayUrl: _gatewayUrl)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (_useDemoMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo mode: using cached responses (no API key needed)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_useDemoMode ? 'Start Demo' : 'Start'),
                        ),
                      ),
                      if (!_useDemoMode && PlatformConfig.hasCamera) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () async {
                            final result = await Navigator.of(context).push<String>(
                              MaterialPageRoute(builder: (_) => const QrScannerDialog()),
                            );
                            if (result != null && mounted) {
                              _handleQrResult(result);
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan Gateway QR',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Demo mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Demo mode',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _useDemoMode,
                        onChanged: (v) => setState(() => _useDemoMode = v),
                      ),
                    ],
                  ),
                  if (!isWeb && !_useDemoMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Or pass via: --dart-define=ANTHROPIC_API_KEY=sk-ant-...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
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
      _start(injectedGateway: pairing.url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR: $e')),
      );
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
    _chatSession?.dispose();
    _sttService?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
