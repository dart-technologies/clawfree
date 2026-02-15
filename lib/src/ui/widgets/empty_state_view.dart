import 'package:flutter/material.dart';
import '../clawfree_icons.dart';
import '../theme.dart';
import 'suggestion_chip.dart';

/// Standardized empty state view for both Phone and Tablet layouts.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.onSend,
    this.agentNames = const [],
    this.showLogo = true,
  });

  final ValueChanged<String> onSend;
  final List<String> agentNames;
  final bool showLogo;

  bool get _hasTravelConcierge =>
      agentNames.any((name) => name.toLowerCase().contains('travel'));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ClawfreeIcons.mic,
                size: showLogo ? 80 : 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'READY FOR COMMANDS',
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SuggestionChip(label: 'Create an agent', onPressed: onSend),
                  SuggestionChip(label: 'Manage OpenClaw', onPressed: onSend),
                  SuggestionChip(label: 'Pair a device', onPressed: onSend),
                  SuggestionChip(label: 'Show skill library', onPressed: onSend),
                  SuggestionChip(label: 'Run a security scan', onPressed: onSend),
                  SuggestionChip(label: 'Check system health', onPressed: onSend),
                  if (_hasTravelConcierge)
                    SuggestionChip(label: 'Plan a trip', onPressed: onSend),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
