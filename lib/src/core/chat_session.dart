import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import '../voice/tts_service.dart';
import 'a2ui_stream_processor.dart';
import 'a2ui_surface_manager.dart';
import 'agent_config_parser.dart';
import 'agent_store.dart';
import 'ai_client.dart';
import 'interaction_router.dart';
import 'message_item.dart';
import 'system_prompt_builder.dart';

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
  })  : _aiClient = aiClient,
        _agentStore = agentStore ?? AgentStore() {
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
      ttsService: ttsService,
    );
    _listenToSurfaces();
    _listenToInteractions();
  }

  final AiClient _aiClient;
  final AgentRepository _agentStore;

  AgentRepository get agentStore => _agentStore;

  final List<MessageItem> _messages = [];
  List<MessageItem> get messages => List.unmodifiable(_messages);

  late final A2uiSurfaceManager _surfaceManager;
  late final SystemPromptBuilder _promptBuilder;
  late final A2uiStreamProcessor _streamProcessor;
  late final A2uiInteractionRouter _interactionRouter;
  SurfaceHost get surfaceHost => _surfaceManager.surfaceHost;

  final List<Map<String, String>> _chatHistory = [];

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

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
        notifyListeners();
      }
    });
  }

  void _listenToInteractions() {
    _surfaceManager.onSubmit.listen(_handleSurfaceInteraction);
  }

  String get _systemPrompt => _promptBuilder.build();

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
      case IgnoredResult():
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Message sending & generation
  // ---------------------------------------------------------------------------

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    _messages.add(MessageItem.user(text: text));
    _chatHistory.add({'role': 'user', 'content': text});
    _lastPrompt = text;
    notifyListeners();

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

      // Wait for the async pipeline to process remaining chunks.
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      if (_shouldSelfCorrect(fullResponse, surfaceCountBefore, attempt)) {
        return _retrySelfCorrection(attempt);
      }

      _onGenerationSuccess(surfaceCountBefore);
    } catch (e, st) {
      genUiLogger.severe('Error generating content (attempt $attempt)', e, st);

      if (attempt < _maxRetries) {
        genUiLogger.info('Retrying generation (attempt ${attempt + 1})...');
        _isProcessing = false;
        notifyListeners();
        return _performGeneration(prompt, attempt: attempt + 1);
      }

      _messages.add(MessageItem.aiText(text: 'Error: $e'));
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
