import 'dart:convert';

import 'package:genui/genui.dart';

import 'agent_config_parser.dart';
import 'agent_store.dart';
import 'message_item.dart';
import '../voice/tts_service.dart';

/// Result of routing a surface interaction.
sealed class InteractionResult {
  const InteractionResult();

  const factory InteractionResult.correction(String prompt) =
      CorrectionResult;
  const factory InteractionResult.agentSaved(MessageItem message) =
      AgentSavedResult;
  const factory InteractionResult.userInput(String text) = UserInputResult;
  const factory InteractionResult.ignored() = IgnoredResult;
  const factory InteractionResult.maxCorrectionsReached(MessageItem message) =
      MaxCorrectionsResult;
}

class CorrectionResult extends InteractionResult {
  const CorrectionResult(this.prompt);
  final String prompt;
}

class AgentSavedResult extends InteractionResult {
  const AgentSavedResult(this.message);
  final MessageItem message;
}

class UserInputResult extends InteractionResult {
  const UserInputResult(this.text);
  final String text;
}

class IgnoredResult extends InteractionResult {
  const IgnoredResult();
}

class MaxCorrectionsResult extends InteractionResult {
  const MaxCorrectionsResult(this.message);
  final MessageItem message;
}

/// Routes surface interactions to the correct handler.
class A2uiInteractionRouter {
  A2uiInteractionRouter({
    required AgentRepository agentStore,
    required TtsService? ttsService,
  })  : _agentStore = agentStore,
        _ttsService = ttsService;

  final AgentRepository _agentStore;
  final TtsService? _ttsService;

  static const _maxCorrectionAttempts = 2;
  int _correctionAttempts = 0;

  /// Reset correction counter (call after a successful surface creation).
  void resetCorrections() => _correctionAttempts = 0;

  /// Route a surface interaction event to the appropriate handler.
  /// Returns an [InteractionResult] describing what should happen next.
  InteractionResult handle(ChatMessage event) {
    final buffer = StringBuffer();
    for (final part in event.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is TextPart) {
        buffer.write(part.text);
      }
    }
    final text = buffer.toString();
    if (text.isEmpty) return const InteractionResult.ignored();

    // Try to parse as JSON to detect structured events
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(text) as Map<String, dynamic>?;
    } catch (_) {}

    // Validation error from SurfaceController
    if (parsed != null && parsed['error'] != null) {
      return _handleValidationError(parsed);
    }

    // User action event (e.g. button press)
    if (parsed != null && parsed['action'] is Map) {
      final action = parsed['action'] as Map<String, dynamic>;
      final actionName = action['name'] as String?;
      final context = action['context'] as Map<String, dynamic>? ?? {};

      if (actionName == 'save_agent') {
        return _handleSaveAgent(context);
      }
    }

    // Legacy path: try to save as agent config from form submission
    final config = AgentConfigParser.tryParse(text);
    if (config != null) {
      _agentStore.addAgent(config);
      genUiLogger.info('Agent saved: ${config['name']}');
    }

    return InteractionResult.userInput(text);
  }

  InteractionResult _handleValidationError(Map<String, dynamic> parsed) {
    final error = parsed['error'];
    final code = error['code'] ?? 'UNKNOWN';
    final message = error['message'] ?? 'Unknown error';
    final correctionPrompt =
        'The previous A2UI JSON had a validation error ($code): $message. '
        'Please fix the JSON and regenerate. Remember: '
        'root component id must be "root", '
        'every ChoicePicker needs "value": [], '
        'use createSurface first then updateComponents.';

    if (_correctionAttempts >= _maxCorrectionAttempts) {
      _correctionAttempts = 0;
      return InteractionResult.maxCorrectionsReached(
        MessageItem.aiText(
          text:
              'I had trouble generating the UI. Let me try a different approach.',
        ),
      );
    }

    _correctionAttempts++;
    return InteractionResult.correction(correctionPrompt);
  }

  InteractionResult _handleSaveAgent(Map<String, dynamic> context) {
    final rawName = context['name']?.toString();
    final name =
        (rawName != null && rawName.isNotEmpty) ? rawName : 'My Agent';
    final model = context['model'];
    final tools = context['tools'];
    final channels = context['channels'];

    final config = <String, dynamic>{
      'name': name.isNotEmpty ? name : 'Untitled Agent',
      'model': model is List && model.isNotEmpty
          ? model.first.toString()
          : 'claude-opus-4-6',
      'tools': tools is List ? tools.cast<String>() : <String>[],
      'channels': channels is List ? channels.cast<String>() : <String>[],
      'config': {
        'version': '1.0',
        'created_by': 'clawfree',
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _agentStore.addAgent(config);
    genUiLogger.info('Agent saved: ${config['name']}');

    final toolsStr = (config['tools'] as List).join(', ');
    final channelsStr = (config['channels'] as List).join(', ');
    final message = MessageItem.aiText(
      text: 'Agent "${config['name']}" saved! '
          'Model: ${config['model']}, '
          'Tools: ${toolsStr.isEmpty ? 'none' : toolsStr}, '
          'Channels: ${channelsStr.isEmpty ? 'none' : channelsStr}.',
    );

    _ttsService?.speak('Agent ${config['name']} saved successfully!');
    return InteractionResult.agentSaved(message);
  }
}
