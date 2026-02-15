import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';
import '../spring_curve.dart';

// ---------------------------------------------------------------------------
// A2UI Catalog registration — overrides the core ChoicePicker by name
// ---------------------------------------------------------------------------

/// Reuse the core ChoicePicker schema so the AI contract doesn't change.
final choicePickerOverrideSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ChoicePicker']),
    'label': S.string(description: 'Display label for the picker.'),
    'variant': S.string(
      enumValues: ['mutuallyExclusive', 'multipleSelection'],
      description: 'Selection mode.',
    ),
    'layout': S.string(
      enumValues: ['segmented', 'wrap', 'grid'],
      description: 'Visual layout of the choices. Defaults to segmented.',
    ),
    'options': S.list(
      items: S.object(
        properties: {'label': S.string(), 'value': S.string()},
        required: ['label', 'value'],
      ),
    ),
    'value': S.list(
      items: S.string(),
      description: 'Currently selected values.',
    ),
  },
  required: ['component', 'options'],
);

/// Catalog builder for the Clawfree-styled ChoicePicker.
Widget choicePickerOverrideCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final label = data['label'] as String?;
  final variant = data['variant'] as String? ?? 'mutuallyExclusive';
  final layout = data['layout'] as String? ?? 'segmented';
  final rawOptions = data['options'] as List? ?? [];
  final options = <_PickerOption>[];
  for (final o in rawOptions) {
    if (o is Map<String, Object?>) {
      options.add(
        _PickerOption(
          label: o['label'] as String? ?? '',
          value: o['value'] as String? ?? '',
        ),
      );
    }
  }

  // Resolve value path for data binding.
  final valueRef = data['value'];
  final path = (valueRef is Map && valueRef.containsKey('path'))
      ? valueRef['path'] as String
      : '${itemContext.id}.value';

  // Seed initial value if it's a literal and the path doesn't have data yet.
  // This ensures pre-populated options (like "Opus 4.6") are selected.
  if (valueRef is List && valueRef.isNotEmpty) {
    // We update the data context so the UI and any dependent buttons find the value.
    itemContext.dataContext.update(path, valueRef);
  }

  if (variant == 'mutuallyExclusive') {
    return _ExclusivePicker(
      itemContext: itemContext,
      label: label,
      options: options,
      path: path,
      layout: layout,
    );
  }
  return _MultiPicker(
    itemContext: itemContext,
    label: label,
    options: options,
    path: path,
    layout: layout,
  );
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _PickerOption {
  const _PickerOption({required this.label, required this.value});
  final String label;
  final String value;
}

// ---------------------------------------------------------------------------
// Mutually exclusive: glass track with sliding highlight
// ---------------------------------------------------------------------------

class _ExclusivePicker extends StatefulWidget {
  const _ExclusivePicker({
    required this.itemContext,
    required this.label,
    required this.options,
    required this.path,
    required this.layout,
  });
  final CatalogItemContext itemContext;
  final String? label;
  final List<_PickerOption> options;
  final String path;
  final String layout;

  @override
  State<_ExclusivePicker> createState() => _ExclusivePickerState();
}

class _ExclusivePickerState extends State<_ExclusivePicker> {
  late ValueNotifier<Object?> _valueNotifier;
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _valueNotifier = widget.itemContext.dataContext.subscribe<Object>(
      widget.path,
    );
    _keys.addAll(List.generate(widget.options.length, (_) => GlobalKey()));
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _selectedIndex() {
    final val = _valueNotifier.value;
    List<String> selected = [];
    if (val is List) {
      selected = val.whereType<String>().toList();
    }
    if (selected.isEmpty) return -1;
    for (var i = 0; i < widget.options.length; i++) {
      if (widget.options[i].value == selected.first) return i;
    }
    return -1;
  }

  void _select(int index) {
    widget.itemContext.dataContext.update(widget.path, [
      widget.options[index].value,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!.toUpperCase(),
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 10,
                letterSpacing: 1.0,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ValueListenableBuilder<Object?>(
          valueListenable: _valueNotifier,
          builder: (context, value, child) {
            final idx = _selectedIndex();

            if (widget.layout == 'wrap') {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(widget.options.length, (i) {
                  final selected = i == idx;
                  return _OptionChip(
                    label: widget.options[i].label,
                    selected: selected,
                    onTap: () => _select(i),
                  );
                }),
              );
            }

            if (widget.layout == 'grid') {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(widget.options.length, (i) {
                      final selected = i == idx;
                      return SizedBox(
                        width: itemWidth,
                        child: _OptionChip(
                          label: widget.options[i].label,
                          selected: selected,
                          onTap: () => _select(i),
                        ),
                      );
                    }),
                  );
                },
              );
            }

            // iOS-style segmented control: solid track, floating selected pill.
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.9),
                borderRadius: ClawfreeBorderRadius.interactive,
                border: Border.all(
                  color: cs.outlineVariant.withValues(
                    alpha: isDark ? 0.15 : 0.25,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final count = widget.options.length;
                  if (count == 0) return const SizedBox.shrink();
                  final itemWidth = (constraints.maxWidth - 6) / count;

                  return SizedBox(
                    height: 44,
                    child: Stack(
                      children: [
                        // Sliding selected pill
                        if (idx >= 0)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: const SpringCurve(),
                            left: 3 + idx * itemWidth,
                            top: 2,
                            bottom: 2,
                            width: itemWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? cs.primary.withValues(alpha: 0.35)
                                    : cs.surface,
                                borderRadius: ClawfreeBorderRadius.small,
                                border: Border.all(
                                  color: isDark
                                      ? cs.primary.withValues(alpha: 0.4)
                                      : cs.outlineVariant.withValues(alpha: 0.15),
                                ),
                                boxShadow: isDark
                                    ? ClawfreeTheme.technicalGlow(
                                        cs.primary,
                                        intensity: 0.2,
                                      )
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        // Option labels
                        Row(
                          children: List.generate(count, (i) {
                            final selected = i == idx;
                            return Expanded(
                              child: GestureDetector(
                                key: _keys[i],
                                onTap: () => _select(i),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          letterSpacing: 0.3,
                                          color: selected
                                              ? (isDark ? cs.primary : cs.onSurface)
                                              : cs.onSurface.withValues(alpha: 0.5),
                                        ),
                                        child: Text(
                                          widget.options[i].label.toUpperCase(),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Technical option chip for non-segmented layouts.
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.2)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: ClawfreeBorderRadius.interactive,
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected ? ClawfreeTheme.technicalGlow(cs.primary, intensity: 0.1) : null,
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multiple selection: FilterChips with Clawfree theme
// ---------------------------------------------------------------------------

class _MultiPicker extends StatefulWidget {
  const _MultiPicker({
    required this.itemContext,
    required this.label,
    required this.options,
    required this.path,
    required this.layout,
  });
  final CatalogItemContext itemContext;
  final String? label;
  final List<_PickerOption> options;
  final String path;
  final String layout;

  @override
  State<_MultiPicker> createState() => _MultiPickerState();
}

class _MultiPickerState extends State<_MultiPicker> {
  late ValueNotifier<Object?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = widget.itemContext.dataContext.subscribe<Object>(
      widget.path,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> _selectedValues() {
    final val = _valueNotifier.value;
    if (val is List) return val.whereType<String>().toList();
    return [];
  }

  void _toggle(String value) {
    final current = List<String>.from(_selectedValues());
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    widget.itemContext.dataContext.update(widget.path, current);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!.toUpperCase(),
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 10,
                letterSpacing: 1.0,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ValueListenableBuilder<Object?>(
          valueListenable: _valueNotifier,
          builder: (context, value, child) {
            final selected = _selectedValues();

            if (widget.layout == 'grid') {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.options.map((opt) {
                      final isSelected = selected.contains(opt.value);
                      return SizedBox(
                        width: itemWidth,
                        child: _OptionChip(
                          label: opt.label,
                          selected: isSelected,
                          onTap: () => _toggle(opt.value),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.map((opt) {
                final isSelected = selected.contains(opt.value);
                return _OptionChip(
                  label: opt.label,
                  selected: isSelected,
                  onTap: () => _toggle(opt.value),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
