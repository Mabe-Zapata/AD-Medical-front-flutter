import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// The bookable services as even cards: name and duration on the left, price on the right. Two columns when there
/// is room, one on a phone.
class ServicePicker extends StatelessWidget {
  const ServicePicker({super.key, required this.services, required this.selected, required this.onSelect});

  final List<MedicalService> services;
  final MedicalService selected;
  final ValueChanged<MedicalService> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 10.0;
      final width = constraints.maxWidth >= 420 ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final service in services) _Card(service, service.id == selected.id, width, () => onSelect(service))],
      );
    },
  );
}

class _Card extends StatelessWidget {
  const _Card(this.service, this.selected, this.width, this.onTap);

  final MedicalService service;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Tokens.orangeTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Tokens.orange : Tokens.slate200, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Tokens.slate900)),
                  const SizedBox(height: 1),
                  Text('${service.durationMin} min', style: const TextStyle(fontSize: 12, color: Tokens.muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              money(service.basePrice, service.currency),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: selected ? Tokens.orangeDeep : Tokens.slate900),
            ),
          ],
        ),
      ),
    ),
  );
}
