import 'dart:async';

import 'package:genui/genui.dart';

import '../voice/tts_service.dart';
import 'a2ui_surface_manager.dart';
import 'ai_client.dart';
import 'message_item.dart';

/// Handles streaming AI responses through the A2UI pipeline.
class A2uiStreamProcessor {
  A2uiStreamProcessor({
    required AiClient aiClient,
    required A2uiSurfaceManager surfaceManager,
    TtsService? ttsService,
  })  : _aiClient = aiClient,
        _surfaceManager = surfaceManager,
        _ttsService = ttsService;

  final AiClient _aiClient;
  final A2uiSurfaceManager _surfaceManager;
  final TtsService? _ttsService;

  /// Debounce interval for notifyListeners during streaming.
  static const _debounceInterval = Duration(milliseconds: 50);

  /// Stream the AI response into [aiMessage], feeding chunks through A2UI.
  /// Returns the full concatenated response.
  ///
  /// [onNotify] is called when the UI should be rebuilt (debounced).
  /// [isDisposed] returns true if the owning session has been disposed.
  Future<String> streamInto({
    required MessageItem aiMessage,
    required String prompt,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required void Function() onNotify,
    required bool Function() isDisposed,
  }) async {
    var fullResponse = '';

    Timer? debounce;
    final textSub = _surfaceManager.textStream.listen(
      (chunk) {
        aiMessage.text = (aiMessage.text ?? '') + chunk;
        debounce?.cancel();
        debounce = Timer(_debounceInterval, () {
          if (!isDisposed()) onNotify();
        });
      },
      onError: (Object error) {
        genUiLogger.warning('Text stream error: $error');
      },
    );

    try {
      final stream = _aiClient.sendStream(
        prompt,
        systemPrompt: systemPrompt,
        history: List.of(history),
      );

      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          fullResponse += chunk;
          _surfaceManager.addChunk(chunk);
        }
      }
    } finally {
      // Flush pending async textStream events before cancelling.
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      debounce?.cancel();
      onNotify();
      await textSub.cancel();
    }

    // Trim trailing whitespace left by JSON block extraction
    aiMessage.text = aiMessage.text?.trim();

    // TTS readback of the full text portion
    final spokenText = aiMessage.text ?? '';
    if (spokenText.isNotEmpty && _ttsService != null) {
      _ttsService.speak(spokenText);
    }

    return fullResponse;
  }

  /// Whether the response contains a JSON code block but no surface was created.
  bool shouldSelfCorrect({
    required String fullResponse,
    required int surfaceCountBefore,
    required int surfaceCountAfter,
    required int attempt,
    required int maxRetries,
  }) {
    final newSurfaceCreated = surfaceCountAfter > surfaceCountBefore;
    return !newSurfaceCreated &&
        containsJsonBlock(fullResponse) &&
        attempt < maxRetries;
  }

  /// Whether [response] contains a fenced JSON code block.
  bool containsJsonBlock(String response) {
    return response.contains('```json') || response.contains('```JSON');
  }
}
