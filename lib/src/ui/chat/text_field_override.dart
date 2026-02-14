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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _controller,
        obscureText: widget.obscureText,
        style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(
            borderRadius: ClawfreeBorderRadius.small,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (v) {
          widget.itemContext.dataContext.update(widget.path, v);
        },
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
