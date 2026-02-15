import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../clawfree_icons.dart';
import '../theme.dart';

/// JSON Schema for the BookingSummary A2UI component.
final bookingSummarySchema = S.object(
  properties: {
    'component': S.string(enumValues: ['BookingSummary']),
    'summary': S.string(description: 'Text summary of what is being booked.'),
    'total': S.string(description: 'Estimated total price.'),
    'hotelPrice': S.string(description: 'Hotel subtotal.'),
    'flightPrice': S.string(description: 'Flight subtotal.'),
    'fees': S.string(description: 'Estimated taxes and fees.'),
    'buttonText': S.string(description: 'Label for the primary booking button. Defaults to "BOOK TRIP".'),
    'action': A2uiSchemas.action(description: 'Action to dispatch on confirm.'),
  },
  required: ['component', 'total', 'action'],
);

/// Catalog builder for the BookingSummary component.
Widget bookingSummaryCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return BookingSummaryComponent(
    itemContext: itemContext,
    summary: data['summary'] as String? ?? '',
    total: data['total'] as String? ?? '',
    hotelPrice: data['hotelPrice'] as String?,
    flightPrice: data['flightPrice'] as String?,
    fees: data['fees'] as String?,
    buttonText: data['buttonText'] as String? ?? 'BOOK TRIP',
    action: data['action'] as Map<String, Object?>? ?? {},
  );
}

class BookingSummaryComponent extends StatelessWidget {
  const BookingSummaryComponent({
    super.key,
    required this.itemContext,
    required this.summary,
    required this.total,
    this.hotelPrice,
    this.flightPrice,
    this.fees,
    this.buttonText = 'BOOK TRIP',
    required this.action,
  });

  final CatalogItemContext itemContext;
  final String summary;
  final String total;
  final String? hotelPrice;
  final String? flightPrice;
  final String? fees;
  final String buttonText;
  final Map<String, Object?> action;

  void _handleConfirm() {
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
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ClawfreeTheme.hudContainerColor,
        borderRadius: ClawfreeBorderRadius.element,
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: ClawfreeBorderRadius.element,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.primary.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(ClawfreeIcons.receipt, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'BOOKING SUMMARY BRIEFING',
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty) ...[
                    Text(
                      summary.toUpperCase(),
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 11,
                        color: ClawfreeTheme.hudTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Cost Breakdown
                  _CostRow('HOTEL ACCOMMODATIONS', hotelPrice ?? '--'),
                  const SizedBox(height: 8),
                  _CostRow('FLIGHT LOGISTICS', flightPrice ?? '--'),
                  const SizedBox(height: 8),
                  _CostRow('ESTIMATED TAXES & FEES', fees ?? '--'),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: ClawfreeTheme.hudDivider, thickness: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL ESTIMATE',
                            style: ClawfreeTheme.technicalStyle(
                              context: context,
                              fontSize: 9,
                              color: ClawfreeTheme.hudTextMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            total,
                            style: ClawfreeTheme.technicalStyle(
                              context: context,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: ClawfreeBorderRadius.interactive,
                          ),
                          elevation: 8,
                          shadowColor: cs.primary.withValues(alpha: 0.5),
                        ),
                        child: Text(
                          buttonText.toUpperCase(),
                          style: ClawfreeTheme.technicalStyle(
                            context: context,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ],
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

class _CostRow extends StatelessWidget {
  const _CostRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: 9,
            color: ClawfreeTheme.hudTextMuted,
          ),
        ),
        Text(
          value,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ClawfreeTheme.hudTextPrimary,
          ),
        ),
      ],
    );
  }
}
