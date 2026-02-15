import 'dart:convert';

import 'package:genui/genui.dart';

import 'agent_config_parser.dart';
import 'agent_store.dart';
import 'gateway_client.dart';
import 'message_item.dart';
import 'openclaw_orchestrator.dart';
import 'prompt_library.dart';
import 'ui_feedback_service.dart';

/// Result of routing a surface interaction.
sealed class InteractionResult {
  const InteractionResult();

  const factory InteractionResult.correction(String prompt) = CorrectionResult;
  const factory InteractionResult.userInput(String text) = UserInputResult;
  const factory InteractionResult.ignored() = IgnoredResult;
  const factory InteractionResult.maxCorrectionsReached(MessageItem message) =
      MaxCorrectionsResult;
  const factory InteractionResult.modeSwitch(
    SessionMode targetMode,
    MessageItem message,
  ) = ModeSwitchResult;
  const factory InteractionResult.systemAction(
    String action,
    MessageItem message,
  ) = SystemActionResult;

  /// Success feedback without mode switch — stay on current screen.
  const factory InteractionResult.successFeedback(
    MessageItem message,
  ) = SuccessFeedbackResult;
}

class CorrectionResult extends InteractionResult {
  const CorrectionResult(this.prompt);
  final String prompt;
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

/// Signals a session mode transition (e.g. onboarding → home).
class ModeSwitchResult extends InteractionResult {
  const ModeSwitchResult(this.targetMode, this.message);
  final SessionMode targetMode;
  final MessageItem message;
}

/// Success feedback without navigation — stays on current screen.
class SuccessFeedbackResult extends InteractionResult {
  const SuccessFeedbackResult(this.message);
  final MessageItem message;
}

/// Signals a system-level action was handled (update, health check, etc.).
class SystemActionResult extends InteractionResult {
  const SystemActionResult(this.action, this.message);
  final String action;
  final MessageItem message;
}

/// Routes surface interactions to the correct handler.
class A2uiInteractionRouter {
  A2uiInteractionRouter({
    required AgentRepository agentStore,
    UIFeedbackService? feedbackService,
    OpenClawOrchestrator? orchestrator,
    GatewayClient? gatewayClient,
  }) : _agentStore = agentStore,
       _feedbackService =
           feedbackService ?? UIFeedbackService(),
       _orchestrator =
           orchestrator ?? OpenClawOrchestrator(agentStore: agentStore),
       _gatewayClient = gatewayClient;

  final AgentRepository _agentStore;
  final UIFeedbackService _feedbackService;
  final OpenClawOrchestrator _orchestrator;
  final GatewayClient? _gatewayClient;

  static const _maxCorrectionAttempts = 2;
  int _correctionAttempts = 0;

  /// Dispatch table mapping action names to handlers.
  late final Map<String, InteractionResult Function(Map<String, dynamic>)>
      _actionHandlers = {
    'navigate': _handleNavigate,
    'save_agent': _handleSaveAgent,
    'save_config': _handleSaveConfig,
    'confirm_setup': _handleConfirmSetup,
    'complete_onboarding': (_) => _handleCompleteOnboarding(),
    'connect_gateway': _handleConnectGateway,
    'copy_pairing_link': _handleCopyPairingLink,
    'generate_itinerary': _handleGenerateItinerary,
    'save_itin': _handleSaveItinerary,
    'book_trip': _handleSaveItinerary,
    'book_flight': _handleSaveItinerary,
    'switch_to_builder': (_) => _handleSwitchToBuilder(),
  };

  /// Reset correction counter (call after a successful surface creation).
  void resetCorrections() => _correctionAttempts = 0;

  /// Action names handled by the manage/system dispatch.
  static const _manageActions = {
    'update_system',
    'check_health',
    'update_api_key',
    'restart_channel',
    'show_logs',
    'clear_agents',
    // Gateway lifecycle (macOS parity)
    'system_restart',
    'system_upgrade',
    // System tools (native parity)
    'system_notify',
    'system_run',
    'location_request',
    // Skill Library & Control Tower
    'activate_skill',
    'deactivate_skill',
    'run_security_scan',
    'rotate_api_keys',
    'export_compliance',
    'export_analytics',
    'refresh_analytics',
    // Agent lifecycle
    'pause_agent',
    'resume_agent',
  };

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

      if (actionName != null) {
        final handler = _actionHandlers[actionName];
        if (handler != null) return handler(context);
        if (_manageActions.contains(actionName)) {
          return _handleManageAction(actionName, context);
        }
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

  InteractionResult _handleNavigate(Map<String, dynamic> context) {
    final text = context['text']?.toString() ?? '';
    if (text.isNotEmpty) return InteractionResult.userInput(text);
    return const InteractionResult.ignored();
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
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : 'My Agent';
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

    // Deploy to remote gateway (fire-and-forget).
    _gatewayClient?.createAgent(config).catchError((Object e) {
      genUiLogger.warning('Remote agent creation failed: $e');
      return <String, dynamic>{};
    });

    final toolsStr = (config['tools'] as List).join(', ');
    final channelsStr = (config['channels'] as List).join(', ');

    genUiLogger.info(
      'Agent "${config['name']}" saved — '
      'Model: ${config['model']}, '
      'Tools: ${toolsStr.isEmpty ? 'none' : toolsStr}, '
      'Channels: ${channelsStr.isEmpty ? 'none' : channelsStr}.',
    );

    // Demo flow: after saving agent, auto-trigger Plan Trip (Story 1→2 seamless)
    // instead of returning to Home.
    return InteractionResult.userInput('Plan a trip');
  }

  // ---------------------------------------------------------------------------
  // Onboarding actions
  // ---------------------------------------------------------------------------

  InteractionResult _handleSaveConfig(Map<String, dynamic> context) {
    genUiLogger.info('Config saved: API Key provided');

    // Return a user input to the AI to advance the conversation to Stage 2 (pairing)
    return const InteractionResult.userInput(
      'Configuration saved! Please show me the pairing screen now.',
    );
  }

  /// Stage 1 confirm: maps to `openclaw onboard --mode anthropic --auth key
  /// --install-daemon --non-interactive --json`.
  InteractionResult _handleConfirmSetup(Map<String, dynamic> context) {
    final apiKey = context['api_key']?.toString() ?? '';
    final cmd = _orchestrator.buildOnboardCommand(
      apiKey: apiKey.isNotEmpty ? apiKey : null,
    );
    genUiLogger.info('Setup confirmed: executing $cmd');

    _feedbackService.info(
      'Setup confirmed. Launching OpenClaw gateway. '
      'Scan the QR code to pair your devices.',
    );

    // Tell the AI to advance to Stage 2 (pairing).
    return InteractionResult.userInput(
      'Setup confirmed. Show me the pairing screen now.',
    );
  }

  /// Stage 2 complete: transition from onboarding → home mode.
  InteractionResult _handleCompleteOnboarding() {
    genUiLogger.info('Onboarding complete — switching to home mode');

    final message = _feedbackService.success(
      'You\'re all set! Say "Create a new agent" to start building, '
      'or "Manage OpenClaw" for system settings.',
    );

    return InteractionResult.modeSwitch(SessionMode.home, message);
  }

  /// "Connect existing gateway" shortcut: skips remaining onboarding.
  InteractionResult _handleConnectGateway(Map<String, dynamic> context) {
    final url = context['gateway_url']?.toString() ?? '';
    final token = context['gateway_token']?.toString() ?? '';

    if (url.isEmpty) {
      return const InteractionResult.userInput(
        'Please provide a gateway URL to connect.',
      );
    }

    _gatewayClient?.updateBaseUrl(url);
    if (token.isNotEmpty) {
      _gatewayClient?.updateToken(token);
    }

    genUiLogger.info('Connected to existing gateway: $url');

    final message = _feedbackService.success(
      'Connected to gateway at $url. Syncing agents and health data.',
    );

    return InteractionResult.modeSwitch(SessionMode.home, message);
  }

  InteractionResult _handleCopyPairingLink(Map<String, dynamic> context) {
    final url = context['url']?.toString() ?? 'http://localhost:18789/pair';
    genUiLogger.info('Pairing requested: $url');

    final message = _feedbackService.info(
      'Opening pairing dialog. Scan the QR code with your device.',
    );

    return InteractionResult.systemAction('copy_pairing_link', message);
  }

  // ---------------------------------------------------------------------------
  // Travel actions
  // ---------------------------------------------------------------------------

  InteractionResult _handleGenerateItinerary(Map<String, dynamic> context) {
    final persona = _extractFirst(context['persona']) ?? 'foodie';
    final city = _extractFirst(context['city']) ?? 'Tokyo';
    final days = _extractFirst(context['days']) ?? '3';

    genUiLogger.info('Generating $persona itinerary for $city ($days days)');

    // Feed a compound keyword back so DemoCacheAiClient matches the right
    // persona-specific response (e.g. "foodie plan").
    return InteractionResult.userInput(
      'Show me the $persona plan for $days days in $city',
    );
  }

  InteractionResult _handleSaveItinerary(Map<String, dynamic> context) {
    final persona = _extractFirst(context['persona']) ?? 'foodie';
    final city = _extractFirst(context['city']) ?? 'Tokyo';

    genUiLogger.info('Itinerary booked: $city ($persona)');

    // Demo flow: stay on itinerary screen after booking (no Home navigation).
    // Return success feedback without mode switch.
    final message = _feedbackService.success(
      'Your $city $persona itinerary has been booked! 🎉',
    );
    return InteractionResult.successFeedback(message);
  }

  /// Extract the first element from a value that may be a List or a String.
  static String? _extractFirst(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Home / manage actions
  // ---------------------------------------------------------------------------

  InteractionResult _handleSwitchToBuilder() {
    genUiLogger.info('Switching to agent builder mode');

    final message = _feedbackService.info(
      'Switching to agent builder. Tell me what agent you want to create.',
    );

    return InteractionResult.modeSwitch(SessionMode.agentBuilder, message);
  }

  InteractionResult _handleManageAction(
    String actionName,
    Map<String, dynamic> context,
  ) {
    final cmd = _orchestrator.commandForAction(actionName, context);

    if (cmd == null) {
      genUiLogger.info('Unknown manage action: $actionName');
      return InteractionResult.systemAction(
        actionName,
        MessageItem.aiText(text: 'Processed action: $actionName.'),
      );
    }

    genUiLogger.info(cmd.logMessage);

    return InteractionResult.systemAction(
      actionName,
      MessageItem.aiText(text: cmd.displayMessage),
    );
  }
}
