import 'ai_client.dart';
import 'demo_scenarios.dart';

/// A demo AI client that replays pre-recorded Opus responses without network.
/// Useful for live demo reliability and offline testing.
class DemoCacheAiClient implements AiClient {
  DemoCacheAiClient({
    Map<String, String>? cachedResponses,
    this.chunkSize = 20,
    this.chunkDelay = const Duration(milliseconds: 30),
  }) : _cachedResponses = cachedResponses ?? defaultResponses;

  final Map<String, String> _cachedResponses;
  final int chunkSize;
  final Duration chunkDelay;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    final response = _findResponse(prompt);
    for (var i = 0; i < response.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, response.length);
      yield response.substring(i, end);
      if (end < response.length) {
        await Future<void>.delayed(chunkDelay);
      }
    }
  }

  String _findResponse(String prompt) {
    final lower = prompt.toLowerCase();
    for (final entry in _cachedResponses.entries) {
      if (entry.key == '_default') continue;
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return _cachedResponses['_default'] ?? 'I can help you with that!';
  }

  @override
  void dispose() {}

  /// Default cached responses for demo scenarios.
  ///
  /// Order matters: entries are checked in insertion order via [contains],
  /// so refinement keywords come before broad creation keywords.
  static final Map<String, String> defaultResponses = {
    // Hackathon demo scenarios (most specific first)
    'show my agents': DemoScenarios.dashboardResponse,
    'test gitdigest': DemoScenarios.agentTestResponse,
    'change the name': DemoScenarios.agentRefinementResponse,
    'gitdigest': DemoScenarios.agentRefinementResponse,
    'summarizes my github': DemoScenarios.agentCreationResponse,
    // Refinement (check before broad keywords)
    'rename': _renameAgentResponse,
    'add': _addToolResponse,
    'test': _testAgentResponse,
    'deploy': _deployResponse,
    'help': _helpResponse,
    'delete': _deleteAgentResponse,
    // Creation
    'create': _createAgentResponse,
    'telegram': _createAgentResponse,
    'github': _createAgentResponse,
    // Dashboard
    'show': _dashboardResponse,
    'dashboard': _dashboardResponse,
    'agents': _dashboardResponse,
    '_default': 'I understand! Let me help you with that. '
        'What kind of agent would you like to create?\n\n'
        'I can set up agents for automation (GitHub bots, CI/CD), '
        'communication (Telegram, Slack, Discord), '
        'or data processing (web scrapers, API integrators).\n\n'
        'Just tell me what you need!',
  };

  static const _catalogId =
      'https://a2ui.org/specification/v0_9/standard_catalog.json';

  static const _createAgentResponse =
      '''Great! I'll help you create an agent. Let me build a configuration form for you.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "agent-form-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "name-field", "model-picker", "tools-picker", "channels-picker", "save-btn"]},
    {"id": "title", "component": "Text", "text": "Create New Agent", "variant": "h4"},
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "text": "My Agent"},
    {"id": "model-picker", "component": "ChoicePicker", "label": "AI Model", "variant": "mutuallyExclusive", "options": [{"label": "Claude Opus 4.6", "value": "claude-opus-4-6"}, {"label": "Claude Sonnet 4.5", "value": "claude-sonnet-4-5"}, {"label": "GPT-4o", "value": "gpt-4o"}], "value": []},
    {"id": "tools-picker", "component": "ChoicePicker", "label": "Tools", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": []},
    {"id": "channels-picker", "component": "ChoicePicker", "label": "Channels", "variant": "multipleSelection", "options": [{"label": "Telegram", "value": "telegram"}, {"label": "Slack", "value": "slack"}, {"label": "Discord", "value": "discord"}], "value": []},
    {"id": "save-btn", "component": "Button", "child": "save-btn-text", "variant": "primary", "action": {"event": {"name": "save_agent", "context": {"name": {"path": "name-field.value"}, "model": {"path": "model-picker.value"}, "tools": {"path": "tools-picker.value"}, "channels": {"path": "channels-picker.value"}}}}},
    {"id": "save-btn-text", "component": "Text", "text": "Save Agent"}
  ]}}
]
```''';

  static const _dashboardResponse =
      '''Here are your agents! Let me generate a dashboard view.

```json
[
  {"version": "v0.9", "createSurface": {"surfaceId": "dashboard-001", "catalogId": "$_catalogId"}},
  {"version": "v0.9", "updateComponents": {"surfaceId": "dashboard-001", "components": [
    {"id": "root", "component": "Column", "children": ["title", "agent-card-1"]},
    {"id": "title", "component": "Text", "text": "Your Agents", "variant": "h4"},
    {"id": "agent-card-1", "component": "Card", "child": "agent-1-info"},
    {"id": "agent-1-info", "component": "Column", "children": ["agent-1-name", "agent-1-status"]},
    {"id": "agent-1-name", "component": "Text", "text": "GitDigest Bot", "variant": "h5"},
    {"id": "agent-1-status", "component": "Text", "text": "Status: Active | Model: Claude Opus 4.6"}
  ]}}
]
```''';

  // ---------------------------------------------------------------------------
  // Multi-turn refinement responses (updateComponents on existing surface)
  // ---------------------------------------------------------------------------

  static const _renameAgentResponse =
      '''Done! I've updated the agent name to "GitHub Digest Bot".

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "name-field", "component": "TextField", "label": "Agent Name", "text": "GitHub Digest Bot"}
  ]}}
]
```''';

  static const _addToolResponse =
      '''I've added the Browser tool to your agent configuration.

```json
[
  {"version": "v0.9", "updateComponents": {"surfaceId": "agent-form-001", "components": [
    {"id": "tools-picker", "component": "ChoicePicker", "label": "Tools", "variant": "multipleSelection", "options": [{"label": "Browser", "value": "browser"}, {"label": "Code Execution", "value": "code"}, {"label": "Web Search", "value": "search"}, {"label": "API Integration", "value": "api"}], "value": ["browser"]}
  ]}}
]
```''';

  static const _testAgentResponse =
      'Your agent is configured and ready to test! '
      'Once deployed via OpenClaw, it will be available on your selected channels. '
      'You can test it by sending messages through Telegram, Slack, or whichever channel you chose.';

  static const _deployResponse =
      'Deploying your agent to OpenClaw! '
      'The agent will be live on your selected channels within a few minutes. '
      'You\'ll receive a confirmation once the deployment is complete.';

  static const _helpResponse =
      'Here\'s what I can do:\n\n'
      '- **Create an agent**: "Create a GitHub automation agent"\n'
      '- **Modify the form**: "Rename it to X" or "Add browser tool"\n'
      '- **Save**: Click the Save Agent button in the form\n'
      '- **View agents**: "Show my agents" or "Open the dashboard"\n'
      '- **Test/Deploy**: "Test the agent" or "Deploy it"\n\n'
      'Just speak or type your request!';

  static const _deleteAgentResponse =
      'Agent deleted. You can create a new one anytime — '
      'just say "Create an agent" to get started again.';
}
