import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/core/ai_client.dart';
import 'src/core/chat_session.dart';
import 'src/core/demo_ai_client.dart';
import 'src/core/platform_config.dart';
import 'src/core/service_locator.dart';
import 'src/ui/chat_screen.dart';
import 'src/ui/clawfree_assets.dart';
import 'src/ui/theme.dart';
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_useDemoMode ? 'Start Demo' : 'Start'),
                    ),
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

  @override
  void dispose() {
    _chatSession?.dispose();
    _sttService?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
