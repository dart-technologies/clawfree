import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../clawfree_icons.dart';
import '../theme.dart';

/// JSON Schema for the FlightTicket A2UI component.
final flightTicketSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FlightTicket']),
    'airline': S.string(description: 'Airline name.'),
    'logoUrl': S.string(description: 'URL for airline logo.'),
    'fromCode': S.string(description: 'Departure airport code (e.g. SFO).'),
    'toCode': S.string(description: 'Arrival airport code (e.g. HND).'),
    'flightNo': S.string(description: 'Flight number (e.g. NH007).'),
    'departureTime': S.string(description: 'Departure time string.'),
    'arrivalTime': S.string(description: 'Arrival time string.'),
    'date': S.string(description: 'Travel date.'),
    'returnFlightNo': S.string(description: 'Return flight number.'),
    'returnDepartureTime': S.string(description: 'Return departure time.'),
    'returnArrivalTime': S.string(description: 'Return arrival time.'),
    'returnDate': S.string(description: 'Return travel date.'),
    'price': S.string(description: 'Ticket price.'),
    'selected': S.boolean(description: 'Whether this ticket is currently selected.'),
    'selectionPath': S.string(description: 'Path in data model to track selection. Defaults to flights.selectedId.'),
    'action': A2uiSchemas.action(description: 'Action to dispatch on select.'),
  },
  required: ['component', 'airline', 'fromCode', 'toCode', 'price', 'action'],
);

/// Catalog-compatible builder for the FlightTicket component.
Widget flightTicketCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return FlightTicketComponent(
    itemContext: itemContext,
    airline: data['airline'] as String? ?? '',
    logoUrl: data['logoUrl'] as String?,
    fromCode: data['fromCode'] as String? ?? '',
    toCode: data['toCode'] as String? ?? '',
    flightNo: data['flightNo'] as String? ?? '',
    departureTime: data['departureTime'] as String? ?? '',
    arrivalTime: data['arrivalTime'] as String? ?? '',
    date: data['date'] as String? ?? '',
    returnFlightNo: data['returnFlightNo'] as String?,
    returnDepartureTime: data['returnDepartureTime'] as String?,
    returnArrivalTime: data['returnArrivalTime'] as String?,
    returnDate: data['returnDate'] as String?,
    price: data['price'] as String? ?? '',
    initialSelected: data['selected'] as bool? ?? false,
    selectionPath: data['selectionPath'] as String? ?? 'flights.selectedId',
    action: data['action'] as Map<String, Object?>? ?? {},
  );
}

class FlightTicketComponent extends StatefulWidget {
  const FlightTicketComponent({
    super.key,
    required this.itemContext,
    required this.airline,
    this.logoUrl,
    required this.fromCode,
    required this.toCode,
    required this.flightNo,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    this.returnFlightNo,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.returnDate,
    required this.price,
    this.initialSelected = false,
    required this.selectionPath,
    required this.action,
  });

  final CatalogItemContext itemContext;
  final String airline;
  final String? logoUrl;
  final String fromCode;
  final String toCode;
  final String flightNo;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final String? returnFlightNo;
  final String? returnDepartureTime;
  final String? returnArrivalTime;
  final String? returnDate;
  final String price;
  final bool initialSelected;
  final String selectionPath;
  final Map<String, Object?> action;

  @override
  State<FlightTicketComponent> createState() => _FlightTicketComponentState();
}

class _FlightTicketComponentState extends State<FlightTicketComponent> {
  late ValueNotifier<Object?> _selectionNotifier;

  @override
  void initState() {
    super.initState();
    _selectionNotifier = widget.itemContext.dataContext.subscribe<Object>(
      widget.selectionPath,
    );
    // Seed initial selection if this ticket was marked as selected
    if (widget.initialSelected && _selectionNotifier.value == null) {
      widget.itemContext.dataContext.update(widget.selectionPath, widget.itemContext.id);
    }
  }

  void _handlePress() {
    // Update local selection state via data model
    widget.itemContext.dataContext.update(widget.selectionPath, widget.itemContext.id);

    if (widget.action.containsKey('event')) {
      final eventMap = widget.action['event'] as Map<String, Object?>;
      final actionName = eventMap['name'] as String;
      final contextDef = eventMap['context'] as Map<String, Object?>?;

      final resolvedCtx = resolveContext(
        widget.itemContext.dataContext,
        contextDef,
      );
      widget.itemContext.dispatchEvent(
        UserActionEvent(
          name: actionName,
          sourceComponentId: widget.itemContext.id,
          context: resolvedCtx,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Object?>(
      valueListenable: _selectionNotifier,
      builder: (context, selectedId, _) {
        final isSelected = selectedId == widget.itemContext.id;

        return GestureDetector(
          onTap: _handlePress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: ClawfreeTheme.hudContainerColor,
              borderRadius: ClawfreeBorderRadius.element,
              border: Border.all(
                color: isSelected ? cs.primary : ClawfreeTheme.hudBorder,
                width: isSelected ? 1.5 : 0.5,
              ),
              boxShadow: isSelected ? ClawfreeTheme.technicalGlow(cs.primary, intensity: 0.3) : null,
            ),
            child: ClipRRect(
              borderRadius: ClawfreeBorderRadius.element,
              child: Column(
                children: [
                  // Header: Airline + Trip Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isSelected ? cs.primary.withValues(alpha: 0.1) : ClawfreeTheme.hudSurfaceFaint,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (widget.logoUrl != null) ...[
                              Image.network(widget.logoUrl!, width: 16, height: 16),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.airline.toUpperCase(),
                              style: ClawfreeTheme.technicalStyle(context: context, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Text(
                          widget.returnFlightNo != null ? 'ROUND TRIP' : 'ONE WAY',
                          style: ClawfreeTheme.technicalStyle(context: context, fontSize: 8, color: ClawfreeTheme.hudTextMuted, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                  
                  // Outbound Leg
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'OUTBOUND • ${widget.date.toUpperCase()}',
                            style: ClawfreeTheme.technicalStyle(
                              context: context,
                              fontSize: 9,
                              color: ClawfreeTheme.hudTextSecondary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _AirportBlock(context, widget.fromCode, widget.departureTime, 'DEPART'),
                            _FlightPath(context, widget.flightNo),
                            _AirportBlock(context, widget.toCode, widget.arrivalTime, 'ARRIVE', alignEnd: true),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Return Leg (Optional)
                  if (widget.returnFlightNo != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: ClawfreeTheme.hudDivider, height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.returnDate != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'RETURN • ${widget.returnDate!.toUpperCase()}',
                                style: ClawfreeTheme.technicalStyle(
                                  context: context,
                                  fontSize: 9,
                                  color: ClawfreeTheme.hudTextSecondary,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _AirportBlock(context, widget.toCode, widget.returnDepartureTime ?? '', 'DEPART'),
                              _FlightPath(context, widget.returnFlightNo!, isReturn: true),
                              _AirportBlock(context, widget.fromCode, widget.returnArrivalTime ?? '', 'ARRIVE', alignEnd: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Perforation Line
                  _Perforation(),

                  // Stub: Price + Selection Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TICKET PRICE', style: ClawfreeTheme.technicalStyle(context: context, fontSize: 8, color: ClawfreeTheme.hudTextMuted)),
                            Text(widget.price, style: ClawfreeTheme.technicalStyle(context: context, fontSize: 16, color: isSelected ? cs.primary : Colors.white, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary : ClawfreeTheme.hudBorder,
                            borderRadius: ClawfreeBorderRadius.pill,
                          ),
                          child: Text(
                            isSelected ? 'SELECTED' : 'SELECT',
                            style: ClawfreeTheme.technicalStyle(context: context, fontSize: 10, color: isSelected ? cs.onPrimary : ClawfreeTheme.hudTextPrimary, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AirportBlock extends StatelessWidget {
  const _AirportBlock(this.context, this.code, this.time, this.label, {this.alignEnd = false});
  final BuildContext context;
  final String code;
  final String time;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: ClawfreeTheme.technicalStyle(context: context, fontSize: 8, color: ClawfreeTheme.hudTextMuted)),
        Text(code, style: ClawfreeTheme.technicalStyle(context: context, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        Text(time, style: ClawfreeTheme.technicalStyle(context: context, fontSize: 12, color: ClawfreeTheme.hudTextPrimary)),
      ],
    );
  }
}

class _FlightPath extends StatelessWidget {
  const _FlightPath(this.context, this.flightNo, {this.isReturn = false});
  final BuildContext context;
  final String flightNo;
  final bool isReturn;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(flightNo, style: ClawfreeTheme.technicalStyle(context: context, fontSize: 9, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 8),
              const Expanded(child: Divider(color: ClawfreeTheme.hudTextFaint, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  isReturn ? ClawfreeIcons.flightLand : ClawfreeIcons.flightTakeoff,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Expanded(child: Divider(color: ClawfreeTheme.hudTextFaint, thickness: 1)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _PunchedHole(isLeft: true),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(),
            size: const Size(double.infinity, 1),
          ),
        ),
        const _PunchedHole(isLeft: false),
      ],
    );
  }
}

class _PunchedHole extends StatelessWidget {
  const _PunchedHole({required this.isLeft});
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 24,
      decoration: BoxDecoration(
        color: ClawfreeTheme.scaffoldBlack,
        borderRadius: BorderRadius.horizontal(
          right: isLeft ? const Radius.circular(12) : Radius.zero,
          left: !isLeft ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ClawfreeTheme.hudBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 4;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
