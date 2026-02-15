import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';

/// JSON Schema for the TextField A2UI component override.
final textFieldOverrideSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['TextField']),
    'label': S.string(description: 'Display label for the input.'),
    'value': S.string(description: 'Initial text content.'),
    'hint': S.string(description: 'Placeholder text.'),
    'obscureText': S.boolean(description: 'Whether to hide input (password).'),
  },
  required: ['component'],
);

/// Catalog builder for the Clawfree-styled TextField.
Widget textFieldOverrideCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final label = data['label'] as String?;
  final hint = data['hint'] as String?;
  final obscureText = data['obscureText'] as bool? ?? false;

  // Resolve value path for data binding.
  final valueRef = data['value'];
  final path = (valueRef is Map && valueRef.containsKey('path'))
      ? valueRef['path'] as String
      : '${itemContext.id}.value';

  // Seed initial value if it's a literal.
  if (valueRef is String && valueRef.isNotEmpty) {
    itemContext.dataContext.update(path, valueRef);
  }

  return _TextFieldWidget(
    itemContext: itemContext,
    label: label,
    hint: hint,
    path: path,
    obscureText: obscureText,
  );
}

class _TextFieldWidget extends StatefulWidget {
  const _TextFieldWidget({
    required this.itemContext,
    this.label,
    this.hint,
    required this.path,
    this.obscureText = false,
  });

  final CatalogItemContext itemContext;
  final String? label;
  final String? hint;
  final String path;
  final bool obscureText;

  @override
  State<_TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<_TextFieldWidget> {
  late final TextEditingController _controller;
  late final ValueNotifier<Object?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = widget.itemContext.dataContext.subscribe<Object>(
      widget.path,
    );
    final initial = _valueNotifier.value?.toString() ?? '';
    _controller = TextEditingController(text: initial);

    _valueNotifier.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    final val = _valueNotifier.value?.toString() ?? '';
    if (val != _controller.text) {
      _controller.text = val;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                widget.label!.toUpperCase(),
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          TextField(
            controller: _controller,
            obscureText: widget.obscureText,
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
              filled: true,
              fillColor: ClawfreeTheme.hudContainerColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: ClawfreeBorderRadius.interactive,
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: ClawfreeBorderRadius.interactive,
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: ClawfreeBorderRadius.interactive,
                borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            onChanged: (v) {
              widget.itemContext.dataContext.update(widget.path, v);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _valueNotifier.removeListener(_onDataChanged);
    _controller.dispose();
    super.dispose();
  }
}
