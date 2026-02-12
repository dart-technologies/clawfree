/// Health status level for a system section.
enum HealthLevel {
  nominal,
  degraded,
  error,
  unknown,
}

/// A single health section (GWAY, LLM, CHAN, TOOL, VOX).
class HealthSection {
  const HealthSection({
    required this.id,
    required this.label,
    this.level = HealthLevel.unknown,
    this.detail = '',
  });

  /// Short identifier shown on compact displays.
  final String id;

  /// Human-readable label.
  final String label;

  /// Current health level.
  final HealthLevel level;

  /// Optional detail string (e.g. "45ms", "2/3 active").
  final String detail;

  HealthSection copyWith({HealthLevel? level, String? detail}) => HealthSection(
        id: id,
        label: label,
        level: level ?? this.level,
        detail: detail ?? this.detail,
      );
}

/// Aggregate health state across all system sections.
///
/// Section labels use human-centric metaphors (Indicators & Barometers)
/// instead of raw technical identifiers.
class HealthState {
  HealthState({
    HealthSection? gateway,
    HealthSection? llm,
    HealthSection? channels,
    HealthSection? tools,
    HealthSection? voice,
  })  : gateway = gateway ??
            const HealthSection(id: 'LINK', label: 'Connectivity'),
        llm = llm ?? const HealthSection(id: 'THINK', label: 'Thinking'),
        channels = channels ??
            const HealthSection(id: 'REACH', label: 'Reach'),
        tools =
            tools ?? const HealthSection(id: 'SKILL', label: 'Skills'),
        voice =
            voice ?? const HealthSection(id: 'EAR', label: 'Listening');

  final HealthSection gateway;
  final HealthSection llm;
  final HealthSection channels;
  final HealthSection tools;
  final HealthSection voice;

  List<HealthSection> get all => [gateway, llm, channels, tools, voice];

  /// Overall system level: worst of all sections.
  HealthLevel get overall {
    if (all.any((s) => s.level == HealthLevel.error)) return HealthLevel.error;
    if (all.any((s) => s.level == HealthLevel.degraded)) {
      return HealthLevel.degraded;
    }
    if (all.every((s) => s.level == HealthLevel.nominal)) {
      return HealthLevel.nominal;
    }
    return HealthLevel.unknown;
  }

  /// Convenience factory for a fully-nominal state (e.g. after onboarding).
  factory HealthState.nominal() => HealthState(
        gateway: const HealthSection(
            id: 'LINK', label: 'Connectivity', level: HealthLevel.nominal),
        llm: const HealthSection(
            id: 'THINK', label: 'Thinking', level: HealthLevel.nominal),
        channels: const HealthSection(
            id: 'REACH', label: 'Reach', level: HealthLevel.nominal),
        tools: const HealthSection(
            id: 'SKILL', label: 'Skills', level: HealthLevel.nominal),
        voice: const HealthSection(
            id: 'EAR', label: 'Listening', level: HealthLevel.nominal),
      );
}
