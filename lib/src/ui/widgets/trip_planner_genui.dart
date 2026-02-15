import 'package:flutter/material.dart';

/// genUI widget for "Plan a Trip" — displays city selection cards.
/// Shows on the left side when Watch triggers plan_a_trip command.
class TripPlannerGenUI extends StatefulWidget {
  const TripPlannerGenUI({
    super.key,
    required this.onCitySelected,
    this.initialCity,
    this.initialDays,
  });

  final void Function(String city, int days) onCitySelected;
  final String? initialCity;
  final int? initialDays;

  @override
  State<TripPlannerGenUI> createState() => _TripPlannerGenUIState();
}

class _TripPlannerGenUIState extends State<TripPlannerGenUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedCity;
  int _selectedDays = 3;

  static const _cities = [
    _CityOption('Tokyo', '🗼', 'Japan', Color(0xFFE91E63)),
    _CityOption('Paris', '🗼', 'France', Color(0xFF2196F3)),
    _CityOption('New York', '🗽', 'USA', Color(0xFF4CAF50)),
    _CityOption('London', '🎡', 'UK', Color(0xFF9C27B0)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedDays = widget.initialDays ?? 3;
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
                  Icon(Icons.flight_takeoff,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Plan a Trip',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // City cards
              Text('Select Destination',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cities.map((city) {
                  final isSelected = _selectedCity == city.name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCity = city.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? city.color.withOpacity(0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? city.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(city.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(city.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                              Text(city.country,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle,
                                color: city.color, size: 16),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Days selector
              Text('Duration',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 6),
              Row(
                children: [3, 5, 7].map((days) {
                  final isSelected = _selectedDays == days;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$days days'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedDays = days),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedCity != null
                      ? () =>
                          widget.onCitySelected(_selectedCity!, _selectedDays)
                      : null,
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(_selectedCity != null
                      ? 'Plan $_selectedDays days in $_selectedCity'
                      : 'Select a city'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityOption {
  const _CityOption(this.name, this.emoji, this.country, this.color);
  final String name;
  final String emoji;
  final String country;
  final Color color;
}
