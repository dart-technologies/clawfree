import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import '../voice/tts_service.dart';
import 'a2ui_stream_processor.dart';
import 'a2ui_surface_manager.dart';
import 'agent_config_parser.dart';
import 'agent_store.dart';
import 'ai_client.dart';
import 'gateway_client.dart';
import 'interaction_router.dart';
import 'message_item.dart';
import 'platform_config.dart';
import 'prompt_library.dart';
import 'system_prompt_builder.dart';
import 'ui_feedback_service.dart';

// Re-export MessageItem so existing `import 'chat_session.dart'` still works.
export 'message_item.dart';

/// Manages the chat session state, wiring the AI client to genUI v0.9.
///
/// Pattern: SurfaceController + A2uiTransportAdapter + Surface widget.
class ChatSession extends ChangeNotifier {
  ChatSession({
    required AiClient aiClient,
    TtsService? ttsService,
    AgentRepository? agentStore,
    GatewayClient? gatewayClient,
  })  : _aiClient = aiClient,
        _agentStore = agentStore ?? AgentStore(),
        _gatewayClient = gatewayClient {
    _feedbackService = UIFeedbackService(ttsService: ttsService);
    _surfaceManager = A2uiSurfaceManager();
    _promptBuilder = SystemPromptBuilder(
      surfaceManager: _surfaceManager,
      agentRepository: _agentStore,
    );
    _streamProcessor = A2uiStreamProcessor(
      aiClient: _aiClient,
      surfaceManager: _surfaceManager,
      ttsService: ttsService,
    );
    _interactionRouter = A2uiInteractionRouter(
      agentStore: _agentStore,
      feedbackService: _feedbackService,
      ttsService: ttsService,
      gatewayClient: _gatewayClient,
    );
    _listenToSurfaces();
    _listenToInteractions();
  }

  final AiClient _aiClient;
  final AgentRepository _agentStore;
  final GatewayClient? _gatewayClient;

  /// The gateway client, if configured (non-demo mode).
  GatewayClient? get gatewayClient => _gatewayClient;

  AgentRepository get agentStore => _agentStore;

  final List<MessageItem> _messages = [];
  List<MessageItem> get messages => List.unmodifiable(_messages);

  late final UIFeedbackService _feedbackService;
  late final A2uiSurfaceManager _surfaceManager;
  late final SystemPromptBuilder _promptBuilder;
  late final A2uiStreamProcessor _streamProcessor;
  late final A2uiInteractionRouter _interactionRouter;
  SurfaceHost get surfaceHost => _surfaceManager.surfaceHost;

  final List<Map<String, String>> _chatHistory = [];

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _activeSurfaceId;
  String? get activeSurfaceId => _activeSurfaceId;

  SessionMode _sessionMode = SessionMode.onboarding;
  SessionMode get sessionMode => _sessionMode;

  /// Whether the session is currently in onboarding mode.
  bool get isOnboarding => _sessionMode == SessionMode.onboarding;

  /// Transition to a new session mode and notify listeners.
  void setMode(SessionMode mode) {
    if (_sessionMode == mode) return;
    _sessionMode = mode;
    notifyListeners();
  }

  /// Current device form factor, set by the UI layer for prompt tailoring.
  DeviceFormFactor? deviceFormFactor;

  /// Callback for navigating back (set by UI layer).
  VoidCallback? onNavigateBack;

  /// Callback invoked when a pairing action is triggered from a genUI surface.
  /// The UI layer can set this to show a native QR code modal.
  void Function(String pairingUrl)? onPairingRequested;

  /// The resolved pairing URL (e.g. `http://192.168.1.5:18789/pair`).
  /// Set by the app bootstrap after detecting the local network address.
  String pairingUrl = 'http://localhost:18789/pair';

  bool _disposed = false;
  String? _lastPrompt;

  /// Max retries on generation error.
  static const _maxRetries = 2;

  // ---------------------------------------------------------------------------
  // Initialization helpers
  // ---------------------------------------------------------------------------

  void _listenToSurfaces() {
    _surfaceManager.surfaceAdded.listen((surfaceId) {
      final exists = _messages.any((m) => m.surfaceId == surfaceId);
      if (!exists) {
        _messages.add(MessageItem.surface(surfaceId: surfaceId));
        _promptBuilder.activeSurfaceIds.add(surfaceId);
      }
      _activeSurfaceId = surfaceId;
      notifyListeners();
    });
  }

  void _listenToInteractions() {
    _surfaceManager.onSubmit.listen(_handleSurfaceInteraction);
  }

  String get _systemPrompt =>
      _promptBuilder.build(mode: _sessionMode, formFactor: deviceFormFactor);

  // ---------------------------------------------------------------------------
  // Surface interaction handling (delegated to router)
  // ---------------------------------------------------------------------------

  void _handleSurfaceInteraction(ChatMessage event) {
    if (_disposed) return;
    genUiLogger.info('Surface interaction: ${event.toJson()}');

    final result = _interactionRouter.handle(event);

    switch (result) {
      case CorrectionResult(:final prompt):
        _chatHistory.add({'role': 'user', 'content': prompt});
        _performGeneration(prompt);
      case AgentSavedResult(:final message):
        _messages.add(message);
        notifyListeners();
      case UserInputResult(:final text):
        _chatHistory.add({'role': 'user', 'content': text});
        _performGeneration(text);
      case MaxCorrectionsResult(:final message):
        _messages.add(message);
        notifyListeners();
      case ModeSwitchResult(:final targetMode, :final message):
        setMode(targetMode);
        _messages.add(message);
        if (targetMode == SessionMode.home) {
          _syncAgentsFromGateway();
        }
        notifyListeners();
      case SystemActionResult(:final action, :final message):
        _messages.add(message);
        // Intercept pairing action to show native QR modal.
        if (action == 'copy_pairing_link') {
          onPairingRequested?.call(pairingUrl);
          notifyListeners();
          break;
        }
        // Feed the action back into the AI so it can generate a manage card.
        _chatHistory.add({
          'role': 'user',
          'content': 'System action triggered: $action',
        });
        _performGeneration('System action triggered: $action');
      case IgnoredResult():
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Gateway agent sync
  // ---------------------------------------------------------------------------

  Future<void> _syncAgentsFromGateway() async {
    if (_gatewayClient == null) return;
    try {
      final remoteAgents = await _gatewayClient.fetchAgents();
      int added = 0;
      for (final agent in remoteAgents) {
        final name = agent['name']?.toString() ?? '';
        if (name.isNotEmpty && _agentStore.findByName(name) == null) {
          _agentStore.addAgent(agent);
          added++;
        }
      }
      if (added > 0) {
        genUiLogger.info('Synced $added agents from gateway');
      }
    } catch (e) {
      genUiLogger.warning('Agent sync failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Message sending & generation
  // ---------------------------------------------------------------------------

  /// Clear the chat history and messages.
  void clearChat() {
    _messages.clear();
    _chatHistory.clear();
    _lastPrompt = null;
    _activeSurfaceId = null;
    notifyListeners();
  }

  /// Voice navigation commands checked before AI generation.
  static final _voiceNavCommands = <RegExp, String>{
    RegExp(r'go\s*back|navigate\s*back|previous\s*screen',
        caseSensitive: false): 'navigate_back',
    RegExp(r'clear\s*(everything|all|chat|screen)',
        caseSensitive: false): 'clear_session',
  };

  /// Keywords that trigger the native pairing modal instead of AI generation.
  static final _pairingPattern = RegExp(
    r'pair|qr\s*code|scan.*device',
    caseSensitive: false,
  );

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _messages.add(MessageItem.user(text: text));
    _chatHistory.add({'role': 'user', 'content': text});
    _lastPrompt = text;
    notifyListeners();

    // Short-circuit: show native QR modal for pairing requests.
    if (_pairingPattern.hasMatch(text) && onPairingRequested != null) {
      _messages.add(MessageItem.aiText(
        text: 'Opening pairing dialog. Scan the QR code with your device.',
      ));
      notifyListeners();
      onPairingRequested!(pairingUrl);
      return;
    }

    // Short-circuit: voice navigation commands.
    for (final entry in _voiceNavCommands.entries) {
      if (entry.key.hasMatch(text)) {
        switch (entry.value) {
          case 'navigate_back':
            _messages.add(MessageItem.aiText(text: 'Going back.'));
            notifyListeners();
            onNavigateBack?.call();
            return;
          case 'clear_session':
            clearChat();
            _messages.add(MessageItem.aiText(text: 'All cleared.'));
            notifyListeners();
            return;
        }
      }
    }

    await _performGeneration(text);
  }

  /// Retry the last failed generation.
  Future<void> retryLastMessage() async {
    if (_lastPrompt == null || _isProcessing) return;
    // Remove the last error message if present
    if (_messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
      notifyListeners();
    }
    await _performGeneration(_lastPrompt!);
  }

  Future<void> _performGeneration(String prompt, {int attempt = 0}) async {
    _isProcessing = true;
    notifyListeners();

    final surfaceCountBefore = _messages.where((m) => m.isSurface).length;

    try {
      final fullResponse = await _streamResponse(prompt);

      _chatHistory.add({'role': 'assistant', 'content': fullResponse});

      // If the response contains JSON, wait for the genUI async pipeline
      // (TransportAdapter → SurfaceController → surfaceAdded) to register
      // the surface. A simple microtask yield loop is insufficient for
      // large payloads; instead we directly await the surfaceAdded stream.
      //
      // Skip the wait if the JSON targets a surfaceId that already exists
      // (e.g. repeated clicks on "manage openclaw" reuse "manage-001").
      final targetsExistingSurface =
          _streamProcessor.containsJsonBlock(fullResponse) &&
          _messages.any((m) =>
              m.isSurface &&
              m.surfaceId != null &&
              fullResponse.contains('"${m.surfaceId}"'));

      if (!_disposed &&
          _streamProcessor.containsJsonBlock(fullResponse) &&
          !targetsExistingSurface) {
        final alreadyCreated =
            _messages.where((m) => m.isSurface).length > surfaceCountBefore;
        if (!alreadyCreated) {
          await _surfaceManager.surfaceAdded
              .first
              .timeout(const Duration(milliseconds: 500), onTimeout: () => '');
        }
      }

      if (_disposed) return;

      if (!targetsExistingSurface &&
          _shouldSelfCorrect(fullResponse, surfaceCountBefore, attempt)) {
        return _retrySelfCorrection(attempt);
      }

      _onGenerationSuccess(surfaceCountBefore);
    } catch (e, st) {
      genUiLogger.severe('Error generating content (attempt $attempt)', e, st);

      if (attempt < _maxRetries) {
        genUiLogger.info('Retrying generation (attempt ${attempt + 1})...');
        _isProcessing = false;
        if (!_disposed) notifyListeners();
        return _performGeneration(prompt, attempt: attempt + 1);
      }

      _messages.add(_feedbackService.error('$e'));
    } finally {
      _isProcessing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String> _streamResponse(String prompt) async {
    final aiMessage = MessageItem.aiText(text: '');
    _messages.add(aiMessage);
    notifyListeners();

    return _streamProcessor.streamInto(
      aiMessage: aiMessage,
      prompt: prompt,
      systemPrompt: _systemPrompt,
      history: _chatHistory,
      onNotify: notifyListeners,
      isDisposed: () => _disposed,
    );
  }

  bool _shouldSelfCorrect(
    String fullResponse,
    int surfaceCountBefore,
    int attempt,
  ) {
    final surfaceCountAfter = _messages.where((m) => m.isSurface).length;
    return _streamProcessor.shouldSelfCorrect(
      fullResponse: fullResponse,
      surfaceCountBefore: surfaceCountBefore,
      surfaceCountAfter: surfaceCountAfter,
      attempt: attempt,
      maxRetries: _maxRetries,
    );
  }

  Future<void> _retrySelfCorrection(int attempt) {
    final correctionPrompt =
        'Your previous response contained JSON but it could not be parsed '
        'as valid A2UI. Please regenerate the A2UI JSON. Remember to use '
        '```json fences, root id must be "root", createSurface first then '
        'updateComponents, and every ChoicePicker needs "value": [].';
    _chatHistory.add({'role': 'user', 'content': correctionPrompt});
    _isProcessing = false;
    notifyListeners();
    return _performGeneration(correctionPrompt, attempt: attempt + 1);
  }

  void _onGenerationSuccess(int surfaceCountBefore) {
    final surfaceCountAfter = _messages.where((m) => m.isSurface).length;
    if (surfaceCountAfter > surfaceCountBefore) {
      _interactionRouter.resetCorrections();
    }
  }

  // ---------------------------------------------------------------------------
  // Agent config export
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? exportAgentConfig() {
    final agents = _agentStore.agents;
    if (agents.isNotEmpty) return agents.last;
    return AgentConfigParser.fromHistory(_chatHistory);
  }

  @override
  void dispose() {
    _disposed = true;
    _surfaceManager.dispose();
    _aiClient.dispose();
    super.dispose();
  }
}
