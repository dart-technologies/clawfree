import 'package:flutter/material.dart';

/// genUI widget for "Create an Agent" — displays agent type and model selection.
/// Shows on the left side when Watch triggers create_agent command.
class AgentBuilderGenUI extends StatefulWidget {
  const AgentBuilderGenUI({
    super.key,
    required this.onAgentCreated,
    this.initialModel,
    this.initialName,
  });

  final void Function(String name, String model, List<String> skills)
      onAgentCreated;
  final String? initialModel;
  final String? initialName;

  @override
  State<AgentBuilderGenUI> createState() => _AgentBuilderGenUIState();
}

class _AgentBuilderGenUIState extends State<AgentBuilderGenUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedTemplate = 'Trip Planner';
  String _selectedModel = 'Claude Opus 4.6';
  final Set<String> _selectedSkills = {'planning'};

  static const _templates = [
    _AgentTemplate('Trip Planner', '✈️', 'Plans trips & itineraries',
        ['travel', 'planning'], Color(0xFF00BFA5)),
    _AgentTemplate('Note Taker', '📝', 'Captures & organizes notes',
        ['notes', 'organization'], Color(0xFF2196F3)),
    _AgentTemplate('Code Assistant', '💻', 'Helps with programming',
        ['coding', 'debugging'], Color(0xFFFF6B35)),
    _AgentTemplate('Research', '🔬', 'Deep research & analysis',
        ['research', 'analysis'], Color(0xFF9C27B0)),
  ];

  static const _models = [
    'Claude Opus 4.6',
    'Claude Sonnet 4.5',
    'Gemini Pro',
    'GPT-4 Turbo',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialModel != null) _selectedModel = widget.initialModel!;
    if (widget.initialName != null) _selectedTemplate = widget.initialName!;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.smart_toy,
                      color: const Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Agent',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Agent templates
              Text('Agent Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _templates.map((t) {
                  final isSelected = _selectedTemplate == t.name;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedTemplate = t.name;
                      _selectedSkills
                        ..clear()
                        ..addAll(t.defaultSkills);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.color.withOpacity(0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? t.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                              Text(t.description,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  )),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle,
                                color: t.color, size: 16),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Model selector
              Text('AI Model',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _models.map((model) {
                  final isSelected = _selectedModel == model;
                  return ChoiceChip(
                    label: Text(model,
                        style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedModel = model),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Create button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onAgentCreated(
                    _selectedTemplate,
                    _selectedModel,
                    _selectedSkills.toList(),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text('Create $_selectedTemplate'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentTemplate {
  const _AgentTemplate(
      this.name, this.emoji, this.description, this.defaultSkills, this.color);
  final String name;
  final String emoji;
  final String description;
  final List<String> defaultSkills;
  final Color color;
}
