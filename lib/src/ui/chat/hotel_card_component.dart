import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../clawfree_icons.dart';
import '../theme.dart';

/// JSON Schema for the HotelCard A2UI component.
final hotelCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['HotelCard']),
    'name': S.string(description: 'Name of the hotel.'),
    'address': S.string(description: 'Full address of the hotel.'),
    'imageUrl': S.string(description: 'Hero image URL.'),
    'price': S.string(description: 'Price per night.'),
    'rating': S.number(description: 'Star rating (1-5).'),
    'amenities': S.list(items: S.string(), description: 'List of key amenities.'),
    'checkIn': S.string(description: 'Check-in time.'),
    'checkOut': S.string(description: 'Check-out time.'),
    'action': A2uiSchemas.action(description: 'Action to dispatch on "View Hotel" or select.'),
  },
  required: ['component', 'name', 'imageUrl', 'price', 'action'],
);

/// Catalog builder for the HotelCard component.
Widget hotelCardCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return HotelCardComponent(
    itemContext: itemContext,
    name: data['name'] as String? ?? '',
    address: data['address'] as String? ?? '',
    imageUrl: data['imageUrl'] as String? ?? '',
    price: data['price'] as String? ?? '',
    rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
    amenities: (data['amenities'] as List?)?.cast<String>() ?? [],
    checkIn: data['checkIn'] as String? ?? '15:00',
    checkOut: data['checkOut'] as String? ?? '11:00',
    action: data['action'] as Map<String, Object?>? ?? {},
  );
}

class HotelCardComponent extends StatelessWidget {
  const HotelCardComponent({
    super.key,
    required this.itemContext,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.price,
    this.rating = 5.0,
    this.amenities = const [],
    this.checkIn = '15:00',
    this.checkOut = '11:00',
    required this.action,
  });

  final CatalogItemContext itemContext;
  final String name;
  final String address;
  final String imageUrl;
  final String price;
  final double rating;
  final List<String> amenities;
  final String checkIn;
  final String checkOut;
  final Map<String, Object?> action;

  void _handlePress() {
    if (action.containsKey('event')) {
      final eventMap = action['event'] as Map<String, Object?>;
      final actionName = eventMap['name'] as String;
      final contextDef = eventMap['context'] as Map<String, Object?>?;

      final resolvedCtx = resolveContext(
        itemContext.dataContext,
        contextDef,
      );
      itemContext.dispatchEvent(
        UserActionEvent(
          name: actionName,
          sourceComponentId: itemContext.id,
          context: resolvedCtx,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ClawfreeTheme.hudContainerColor,
        borderRadius: ClawfreeBorderRadius.element,
        border: Border.all(
          color: ClawfreeTheme.hudBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: ClawfreeBorderRadius.element,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image with Price Badge
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ClawfreeTheme.hudOverlayColor,
                      borderRadius: ClawfreeBorderRadius.pill,
                      border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '$price/NIGHT',
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                // Gradient overlay for text legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          ClawfreeTheme.glassOverlayColor,
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? ClawfreeIcons.star : ClawfreeIcons.starBorder,
                            size: 14,
                            color: i < rating ? ClawfreeTheme.ratingGold : ClawfreeTheme.hudTextFaint,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name.toUpperCase(),
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.toUpperCase(),
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: 9,
                      color: ClawfreeTheme.hudTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _VitalsBlock(context, 'CHECK-IN', checkIn),
                      _VitalsBlock(context, 'CHECK-OUT', checkOut),
                      _VitalsBlock(context, 'STATUS', 'AVAILABLE', color: ClawfreeTheme.hudActive),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (amenities.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities.map((a) => _AmenityTag(a)).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: ClawfreeBorderRadius.interactive,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'VIEW PROPERTY DETAILS',
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalsBlock extends StatelessWidget {
  const _VitalsBlock(this.context, this.label, this.value, {this.color});
  final BuildContext context;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClawfreeTheme.technicalStyle(context: context, fontSize: 8, color: ClawfreeTheme.hudTextMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color ?? ClawfreeTheme.hudTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _AmenityTag extends StatelessWidget {
  const _AmenityTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClawfreeTheme.hudSurfaceFaint,
        borderRadius: ClawfreeBorderRadius.tiny,
        border: Border.all(color: ClawfreeTheme.hudBorder),
      ),
      child: Text(
        label.toUpperCase(),
        style: ClawfreeTheme.technicalStyle(context: context, fontSize: 8, color: ClawfreeTheme.hudTextSecondary),
      ),
    );
  }
}
