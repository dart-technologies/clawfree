import 'dart:async';

import 'package:genui/genui.dart';

import '../voice/voice_controller.dart';
import 'a2ui_surface_manager.dart';
import 'ai_client.dart';
import 'message_item.dart';

/// Handles streaming AI responses through the A2UI pipeline.
class A2uiStreamProcessor {
  A2uiStreamProcessor({
    required AiClient aiClient,
    required A2uiSurfaceManager surfaceManager,
    VoiceController? voiceController,
  }) : _aiClient = aiClient,
       _surfaceManager = surfaceManager,
       _voiceController = voiceController;

  final AiClient _aiClient;
  final A2uiSurfaceManager _surfaceManager;
  final VoiceController? _voiceController;

  /// Debounce interval for notifyListeners during streaming (higher for stability).
  static const _debounceInterval = Duration(milliseconds: 100);

  /// Stream the AI response into [aiMessage], feeding chunks through A2UI.
  /// Returns the full concatenated response.
  ///
  /// [onNotify] is called when the UI should be rebuilt (debounced).
  /// [isDisposed] returns true if the owning session has been disposed.
  Future<String> streamInto({
    required AiTextMessage aiMessage,
    required String prompt,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required void Function() onNotify,
    required bool Function() isDisposed,
    void Function(String transcript, bool isFinal)? onTranscriptionResult,
  }) async {
    // Flush parser state from previous response to prevent text leakage.
    _surfaceManager.resetTransport();

    var fullResponse = '';

    Timer? debounce;
    final textSub = _surfaceManager.textStream.listen(
      (chunk) {
        aiMessage.text = '${aiMessage.text}$chunk';
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
        history: List.unmodifiable(history),
      );

      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          fullResponse += chunk;
          _surfaceManager.addChunk(chunk);
        }
      }
    } finally {
      // Flush pending async textStream events before cancelling.
      for (var i = 0; i < 2; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      debounce?.cancel();
      onNotify();
      await textSub.cancel();
    }

    // Trim trailing whitespace left by JSON block extraction
    aiMessage.text = aiMessage.text?.trim();

    // Unified voice orchestration readback
    final spokenText = aiMessage.text ?? ''; // text is non-null for AiTextMessage but getter returns String?
    if (spokenText.isNotEmpty && _voiceController != null) {
      await _voiceController.speak(spokenText, onResult: onTranscriptionResult);
    }

    return fullResponse;
  }

  /// Whether the response contains a JSON code block but no surface was created.
  ///
  /// Returns true if self-correction should be attempted.
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
