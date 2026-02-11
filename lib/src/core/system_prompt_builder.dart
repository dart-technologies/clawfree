import 'a2ui_surface_manager.dart';
import 'agent_store.dart';
import 'prompt_library.dart';

/// Builds the system prompt from A2UI schema, active surfaces, and saved agents.
class SystemPromptBuilder {
  SystemPromptBuilder({
    required A2uiSurfaceManager surfaceManager,
    required AgentRepository agentRepository,
  })  : _surfaceManager = surfaceManager,
        _agentRepository = agentRepository {
    _baseSystemPrompt = PromptLibrary.systemPrompt(
      a2uiSchema: _surfaceManager.buildSchemaJson(),
      catalogRules: _surfaceManager.catalogRules,
    );
  }

  final A2uiSurfaceManager _surfaceManager;
  final AgentRepository _agentRepository;

  late final String _baseSystemPrompt;

  /// Track active surface IDs for multi-turn refinement.
  final List<String> activeSurfaceIds = [];

  /// Build the full system prompt including active surfaces and saved agents.
  String build() {
    final buf = StringBuffer(_baseSystemPrompt);

    if (activeSurfaceIds.isNotEmpty) {
      final surfaceContext =
          activeSurfaceIds.map((id) => '- $id').join('\n');
      buf.writeln('\n\n# Active Surfaces');
      buf.writeln(
          'The following surfaces are currently rendered. '
          'Use updateComponents to modify them instead of creating new surfaces:');
      buf.writeln(surfaceContext);
    }

    if (_agentRepository.agents.isNotEmpty) {
      buf.writeln('\n\n# Saved Agents');
      buf.writeln(
          'The user has saved the following agents. '
          'Use this info when generating dashboards or responding to queries:');
      for (final agent in _agentRepository.agents) {
        final tools = (agent['tools'] as List?)?.join(', ') ?? 'none';
        buf.writeln(
            '- ${agent['name']} (model: ${agent['model']}, tools: $tools)');
      }
    }

    return buf.toString();
  }
}
