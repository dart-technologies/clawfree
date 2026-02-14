import 'platform_config.dart';

/// Fluent builder for composing system prompts from reusable sections.
class PromptBuilder {
  final List<_PromptSection> _sections = [];

  /// Add a named section with a header.
  PromptBuilder section(String name, String content) {
    _sections.add(_PromptSection(name: name, content: content));
    return this;
  }

  /// Add raw content without a header.
  PromptBuilder raw(String content) {
    _sections.add(_PromptSection(content: content));
    return this;
  }

  /// Add an A2UI schema block wrapped in XML tags.
  PromptBuilder schema(String json) {
    _sections.add(
      _PromptSection(content: '<a2ui_schema>\n$json\n</a2ui_schema>'),
    );
    return this;
  }

  /// Add catalog rules (raw, no header).
  PromptBuilder rules(String rules) {
    if (rules.isNotEmpty) {
      _sections.add(_PromptSection(content: rules));
    }
    return this;
  }

  /// Add agent context — no-op when the list is empty.
  PromptBuilder agentContext(List<Map<String, dynamic>> agents) {
    if (agents.isEmpty) return this;
    final buf = StringBuffer();
    buf.writeln(
      'The user has saved the following agents. '
      'Use this info when generating dashboards or responding to queries:',
    );
    for (final agent in agents) {
      final tools = (agent['tools'] as List?)?.join(', ') ?? 'none';
      buf.writeln(
        '- ${agent['name']} (model: ${agent['model']}, tools: $tools)',
      );
    }
    _sections.add(
      _PromptSection(name: 'Saved Agents', content: buf.toString()),
    );
    return this;
  }

  /// Add active surfaces context — no-op when the list is empty.
  PromptBuilder activeSurfaces(List<String> surfaceIds) {
    if (surfaceIds.isEmpty) return this;
    final surfaceContext = surfaceIds.map((id) => '- $id').join('\n');
    _sections.add(
      _PromptSection(
        name: 'Active Surfaces',
        content:
            'The following surfaces are currently rendered. '
            'Use updateComponents to modify them instead of creating new surfaces:\n'
            '$surfaceContext',
      ),
    );
    return this;
  }

  /// Add device context — no-op when null.
  PromptBuilder deviceContext(DeviceFormFactor? formFactor) {
    if (formFactor == null) return this;
    final guidance = switch (formFactor) {
      DeviceFormFactor.phone =>
        'The user is on an iPhone. Keep spoken responses to 1-2 sentences. '
            'Use compact single-card A2UI layouts. Say "your phone" not "the dashboard".',
      DeviceFormFactor.tablet =>
        'The user is on an iPad. Use ResponsiveContainer for multi-card layouts. '
            'Spoken responses can be 2-3 sentences. Reference "your iPad" in speech.',
      DeviceFormFactor.desktop =>
        'The user is on macOS desktop. Full-width layouts welcome. '
            'Spoken responses can be slightly longer (2-4 sentences).',
      DeviceFormFactor.watch =>
        'The user is on Apple Watch. Voice-ONLY responses — do NOT generate A2UI JSON. '
            'Keep to 1 sentence max. Use "your Watch" in speech.',
      DeviceFormFactor.glasses =>
        'The user is on AR/VR Glasses. Spoken responses only (no UI). '
            'Keep to 1 sentence. Avoid visual references like "tap" or "see".',
    };
    _sections.add(_PromptSection(name: 'Device Context', content: guidance));
    return this;
  }

  /// Assemble the final prompt string.
  String build() {
    final buf = StringBuffer();
    for (var i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      if (i > 0) buf.write('\n\n');
      if (section.name != null) {
        buf.writeln('# ${section.name}');
      }
      buf.write(section.content);
    }
    return buf.toString();
  }
}

class _PromptSection {
  const _PromptSection({this.name, required this.content});
  final String? name;
  final String content;
}
