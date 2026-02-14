import 'agent_store.dart';
import 'gateway_client.dart';

/// Data class holding log, TTS, and display text for an OpenClaw action.
class OpenClawCommand {
  const OpenClawCommand({
    required this.logMessage,
    required this.ttsMessage,
    required this.displayMessage,
    this.cliCommand,
  });

  final String logMessage;
  final String ttsMessage;
  final String displayMessage;
  final String? cliCommand;
}

/// Maps action names to OpenClaw CLI commands and user-facing messages.
class OpenClawOrchestrator {
  OpenClawOrchestrator({
    required AgentRepository agentStore,
    GatewayClient? gatewayClient,
  }) : _agentStore = agentStore,
       _gatewayClient = gatewayClient;

  final AgentRepository _agentStore;
  final GatewayClient? _gatewayClient;

  /// Returns the [OpenClawCommand] for a manage/system action, or `null` if
  /// the action name is unknown.
  OpenClawCommand? commandForAction(
    String actionName,
    Map<String, dynamic> context,
  ) {
    final cmd = switch (actionName) {
      // --- Manage actions ---
      'update_system' => const OpenClawCommand(
        logMessage: 'Executing: openclaw upgrade',
        ttsMessage: 'Updating OpenClaw to the latest stable version.',
        displayMessage:
            'Updating OpenClaw\u2026 Running `openclaw upgrade`. '
            'I\'ll let you know when it\'s done.',
        cliCommand: 'openclaw upgrade',
      ),
      'check_health' => OpenClawCommand(
        logMessage: 'Executing: openclaw status --json',
        ttsMessage: 'Checking gateway health.',
        displayMessage: _gatewayClient != null
            ? 'Checking gateway at ${_gatewayClient.baseUrl}\u2026 '
                  'Running `openclaw status`. '
                  'Connectivity, latency, and channel health coming right up.'
            : 'Checking gateway status\u2026 Running `openclaw status`. '
                  'Connectivity, latency, and channel health coming right up.',
        cliCommand: 'openclaw status --json',
      ),
      'update_api_key' => const OpenClawCommand(
        logMessage: 'Presenting secure key input',
        ttsMessage: 'Ready for your new API key.',
        displayMessage:
            'Please provide your new Anthropic API key. '
            'I\'ll update the gateway configuration securely.',
      ),
      'restart_channel' => const OpenClawCommand(
        logMessage: 'Executing: openclaw onboard --install-daemon',
        ttsMessage: 'Restarting the messaging bridge.',
        displayMessage:
            'Restarting messaging bridge\u2026 Running `openclaw onboard --install-daemon`. '
            'Your channels will reconnect shortly.',
        cliCommand: 'openclaw onboard --install-daemon',
      ),
      'show_logs' => const OpenClawCommand(
        logMessage: 'Fetching last 5 log lines',
        ttsMessage: 'Here are the most recent logs.',
        displayMessage:
            'Fetching the last 5 error log entries from the OpenClaw gateway.',
      ),
      'clear_agents' => const OpenClawCommand(
        logMessage: 'Clearing agent store',
        ttsMessage: 'All agents have been cleared.',
        displayMessage:
            'Clearing all agents from the local store. '
            'Your gateway is reset for a fresh start.',
      ),
      // --- Gateway lifecycle (macOS SSH parity) ---
      'system_restart' => const OpenClawCommand(
        logMessage: 'POST /restart \u2192 OpenClaw gateway',
        ttsMessage: 'Restarting the OpenClaw gateway.',
        displayMessage:
            'Restarting gateway\u2026 Sending restart signal to OpenClaw. '
            'Services will reconnect automatically.',
      ),
      'system_upgrade' => const OpenClawCommand(
        logMessage: 'Executing: openclaw upgrade via terminal bridge',
        ttsMessage: 'Upgrading OpenClaw to the latest version.',
        displayMessage:
            'Upgrading OpenClaw\u2026 Pulling the latest stable image and restarting. '
            'This may take a moment.',
        cliCommand: 'openclaw upgrade',
      ),
      // --- System tools (native parity) ---
      'system_notify' => const OpenClawCommand(
        logMessage: 'Dispatching local notification',
        ttsMessage: 'Notification sent.',
        displayMessage: 'Notification dispatched to your device.',
      ),
      'system_run' => const OpenClawCommand(
        logMessage: 'System command requested \u2014 awaiting voice approval',
        ttsMessage:
            'A command needs your approval. Say "Allow" to execute or "Deny" to cancel.',
        displayMessage:
            'An agent is requesting to run a system command. '
            'Review the command below and say "Allow" to execute, or "Deny" to cancel.',
      ),
      'location_request' => const OpenClawCommand(
        logMessage: 'Location permission requested',
        ttsMessage: 'Your agent needs your location. Say "Allow" to share.',
        displayMessage:
            'An agent is requesting your current location to provide local results. '
            'Say "Allow" to share your location, or "Deny" to skip.',
      ),
      // --- Skill Library & Control Tower ---
      'activate_skill' => OpenClawCommand(
        logMessage: 'Activating skill: ${context['name'] ?? 'unknown'}',
        ttsMessage: 'Skill activated.',
        displayMessage:
            'Activated skill "${context['name'] ?? 'unknown'}". Available to all agents.',
      ),
      'deactivate_skill' => OpenClawCommand(
        logMessage: 'Deactivating skill: ${context['name'] ?? 'unknown'}',
        ttsMessage: 'Skill deactivated.',
        displayMessage: 'Deactivated skill "${context['name'] ?? 'unknown'}".',
      ),
      'run_security_scan' => const OpenClawCommand(
        logMessage: 'Initiating full security scan',
        ttsMessage: 'Running security scan.',
        displayMessage:
            'Initiating full scan across agents, skills, and dependencies.',
      ),
      'rotate_api_keys' => const OpenClawCommand(
        logMessage: 'Rotating all API keys',
        ttsMessage: 'Rotating all API keys.',
        displayMessage: 'New keys distributed to active agents automatically.',
      ),
      'export_compliance' => const OpenClawCommand(
        logMessage: 'Exporting compliance report',
        ttsMessage: 'Exporting compliance report.',
        displayMessage: 'Generating SOC2/GDPR/HIPAA report as PDF.',
      ),
      'export_analytics' => const OpenClawCommand(
        logMessage: 'Exporting analytics data',
        ttsMessage: 'Exporting analytics.',
        displayMessage: 'Exporting performance data to CSV.',
      ),
      _ => null,
    };

    // Side effect: clear agents when that action fires.
    if (actionName == 'clear_agents') {
      _agentStore.clear();
    }

    return cmd;
  }

  /// Build the onboard CLI command string.
  String buildOnboardCommand({String? apiKey}) {
    final keyArg = (apiKey != null && apiKey.isNotEmpty)
        ? ' --api-key $apiKey'
        : '';
    return 'openclaw onboard --mode anthropic --auth key'
        ' --install-daemon --non-interactive --json$keyArg';
  }
}
