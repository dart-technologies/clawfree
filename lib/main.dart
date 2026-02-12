import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'src/core/ai_client.dart';
import 'src/core/chat_session.dart';
import 'src/core/demo_ai_client.dart';
import 'src/core/platform_config.dart';
import 'src/core/service_locator.dart';
import 'src/ui/chat_screen.dart';
import 'src/ui/clawfree_assets.dart';
import 'src/ui/splash_screen.dart';
import 'src/ui/theme.dart';
import 'src/voice/stt_service.dart';
import 'src/voice/tts_service.dart';
import 'src/voice/voice_controller.dart';
import 'src/voice/voice_service_factory.dart';

/// Compile-time constants from --dart-define
const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
const _gatewayUrl = String.fromEnvironment('GATEWAY_URL', defaultValue: '');
const _demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOut,
      home: const _SplashGate(),
    );
  }
}

/// Shows the animated splash screen, then transitions to the home screen.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }
    return const ClawfreeHome();
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
  final _apiKeyController = TextEditingController(text: _apiKey);
  bool _useDemoMode = _demoMode;

  void _start() {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty && !PlatformConfig.isWeb && !_useDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Anthropic API key')),
      );
      return;
    }

    final AiClient aiClient;
    if (_useDemoMode) {
      aiClient = DemoCacheAiClient();
    } else {
      aiClient = AnthropicAiClient(
        apiKey: key,
        baseUrl: PlatformConfig.resolveBaseUrl(gatewayUrl: _gatewayUrl),
      );
    }

    final voice = VoiceServiceFactory.create(isDemo: _useDemoMode);

    sl.reset();
    sl.register<AiClient>(aiClient);
    sl.register<TtsService>(voice.tts);
    sl.register<SttService>(voice.stt);
    sl.register<VoiceController>(
      VoiceController(stt: voice.stt, tts: voice.tts),
    );

    _chatSession = ChatSession(
      aiClient: sl.get<AiClient>(),
      ttsService: sl.tryGet<TtsService>(),
    );
    _sttService = sl.tryGet<SttService>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatSession: _chatSession!,
          sttService: _sttService,
          voiceController: sl.tryGet<VoiceController>(),
          onNavigateHome: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((_) {
      _chatSession?.dispose();
      _chatSession = null;
      _sttService?.dispose();
      _sttService = null;
      sl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = PlatformConfig.isWeb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ClawfreeTheme.darkBg : ClawfreeTheme.lightBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
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
                  const SizedBox(height: 20),
                  Text(
                    'clawfree',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hands-free AI agent creation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (!isWeb && !_useDemoMode)
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'Anthropic API Key',
                        hintText: 'sk-ant-...',
                        prefixIcon: const Icon(Icons.key_outlined),
                        // Uses theme's inputDecorationTheme
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _start(),
                    ),
                  if (isWeb && !_useDemoMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? ClawfreeTheme.darkCard
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                            ClawfreeTheme.radiusM),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            size: 18,
                            color: ClawfreeTheme.teal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gateway: ${PlatformConfig.resolveBaseUrl(gatewayUrl: _gatewayUrl)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_useDemoMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ClawfreeTheme.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            ClawfreeTheme.radiusM),
                        border: Border.all(
                          color: ClawfreeTheme.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: ClawfreeTheme.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo mode — cached responses, no API key needed',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? ClawfreeTheme.teal
                                    : ClawfreeTheme.teal.withValues(
                                        alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(
                        _useDemoMode ? 'Start Demo' : 'Start',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        color: isDark ? Colors.white24 : Colors.black26,
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

  @override
  void dispose() {
    _chatSession?.dispose();
    _sttService?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
