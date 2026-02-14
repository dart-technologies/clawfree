import 'a2ui_surface_manager.dart';
import 'agent_store.dart';
import 'platform_config.dart';
import 'prompt_library.dart';

/// Builds the system prompt from A2UI schema, active surfaces, and saved agents.
class SystemPromptBuilder {
  SystemPromptBuilder({
    required A2uiSurfaceManager surfaceManager,
    required AgentRepository agentRepository,
  }) : _surfaceManager = surfaceManager,
       _agentRepository = agentRepository;

  final A2uiSurfaceManager _surfaceManager;
  final AgentRepository _agentRepository;

  /// Track active surface IDs for multi-turn refinement.
  final List<String> activeSurfaceIds = [];

  /// Build the full system prompt for the given [mode].
  String build({
    SessionMode mode = SessionMode.agentBuilder,
    DeviceFormFactor? formFactor,
  }) {
    switch (mode) {
      case SessionMode.onboarding:
        return PromptLibrary.onboardingPrompt(
          a2uiSchema: _surfaceManager.buildSchemaJson(),
        ).deviceContext(formFactor).build();
      case SessionMode.home:
        return PromptLibrary.homePrompt(
              a2uiSchema: _surfaceManager.buildSchemaJson(),
              catalogRules: _surfaceManager.catalogRules,
            )
            .agentContext(_agentRepository.agents)
            .deviceContext(formFactor)
            .build();
      case SessionMode.agentBuilder:
        return PromptLibrary.systemPrompt(
              a2uiSchema: _surfaceManager.buildSchemaJson(),
              catalogRules: _surfaceManager.catalogRules,
            )
            .activeSurfaces(activeSurfaceIds)
            .agentContext(_agentRepository.agents)
            .deviceContext(formFactor)
            .build();
    }
  }
}
