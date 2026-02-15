import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A standardized action chip for voice/chat suggestions.
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label.toUpperCase(),
        style: ClawfreeTheme.technicalStyle(
          context: context,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed(label);
      },
      shape: const StadiumBorder(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),
    );
  }
}
