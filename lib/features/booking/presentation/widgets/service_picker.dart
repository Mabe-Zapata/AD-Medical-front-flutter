import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

class ServicePicker extends StatelessWidget {
  const ServicePicker({super.key, required this.services, required this.selected, required this.onSelect});

  final List<MedicalService> services;
  final MedicalService selected;
  final ValueChanged<MedicalService> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final service in services)
        InkWell(
          borderRadius: BorderRadius.circular(Tokens.radiusSm + 4),
          onTap: () => onSelect(service),
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: service.id == selected.id ? Tokens.orangeTint : Colors.white,
              borderRadius: BorderRadius.circular(Tokens.radiusSm + 4),
              border: Border.all(color: service.id == selected.id ? Tokens.orange : Tokens.slate200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Tokens.slate900)),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMin} min · ${money(service.basePrice, service.currency)}',
                  style: const TextStyle(fontSize: 12, color: Tokens.muted),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
