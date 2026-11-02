import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

/// Public catalog: lab tests and bookable services.
class CatalogSection extends StatelessWidget {
  const CatalogSection({super.key, required this.testTypes, required this.services, required this.onBook});

  final List<LabTestType> testTypes;
  final List<MedicalService> services;
  final void Function(String serviceId) onBook;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Tokens.orangeTint,
    padding: const EdgeInsets.symmetric(vertical: 72),
    child: Constrained(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Pruebas'),
          const SizedBox(height: 12),
          const Text(
            'Lo que analizamos',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Tokens.slate900),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 560 ? 2 : 1);
              const gap = 16.0;
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final test in testTypes) SizedBox(width: width, child: _TestCard(test))],
              );
            },
          ),
          const SizedBox(height: 56),
          const Text(
            'Servicios que puedes reservar',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Tokens.slate900),
          ),
          const SizedBox(height: 20),
          for (final service in services) ...[
            _ServiceRow(service, onBook: () => onBook(service.id)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class _TestCard extends StatelessWidget {
  const _TestCard(this.test);

  final LabTestType test;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(test.code, Tokens.orangeDeep),
        const SizedBox(height: 12),
        Text(test.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tokens.slate900)),
        const SizedBox(height: 6),
        Text(test.description ?? '', style: const TextStyle(color: Tokens.muted, fontSize: 13, height: 1.5)),
        if (test.defaultUnit != null) ...[
          const SizedBox(height: 10),
          Text('Unidad: ${test.defaultUnit}', style: const TextStyle(color: Tokens.slate400, fontSize: 12)),
        ],
      ],
    ),
  );
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow(this.service, {required this.onBook});

  final MedicalService service;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Tokens.slate900)),
            const SizedBox(height: 2),
            Text('${service.durationMin} min', style: const TextStyle(color: Tokens.muted, fontSize: 13)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              money(service.basePrice, service.currency),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tokens.orangeDeep),
            ),
            const SizedBox(width: 20),
            FilledButton(onPressed: onBook, child: const Text('Reservar')),
          ],
        ),
      ],
    ),
  );
}
