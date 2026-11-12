import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

/// Public catalog: lab tests and bookable services. A rounded white "island" on the page background, not a band.
class CatalogSection extends StatelessWidget {
  const CatalogSection({super.key, required this.testTypes, required this.services, required this.onBook});

  final List<LabTestType> testTypes;
  final List<MedicalService> services;
  final void Function(String serviceId) onBook;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Constrained(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 20, vertical: wide ? 56 : 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.12), blurRadius: 70, offset: const Offset(0, 30))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Pruebas', color: Tokens.blueText),
              const SizedBox(height: 12),
              const Text(
                'Lo que analizamos',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Tokens.slate900),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: const Text(
                  'Estas son las pruebas que procesa el laboratorio. Reserva el servicio que corresponda y '
                  'consulta el resultado en tu portal cuando esté validado.',
                  style: TextStyle(fontSize: 16, height: 1.6, color: Tokens.slate600),
                ),
              ),
              const SizedBox(height: 28),
              _grid(
                columnsFor: (width) => width >= 900 ? 4 : (width >= 560 ? 2 : 1),
                children: [for (final test in testTypes) _TestCard(test)],
              ),
              const SizedBox(height: 48),
              const SectionLabel('Reservas'),
              const SizedBox(height: 12),
              const Text(
                'Servicios que puedes reservar',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Tokens.slate900),
              ),
              const SizedBox(height: 20),
              _grid(
                columnsFor: (width) => width >= 900 ? 2 : 1,
                children: [for (final service in services) _ServiceRow(service, onBook: () => onBook(service.id))],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid({required int Function(double width) columnsFor, required List<Widget> children}) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = columnsFor(constraints.maxWidth);
      const gap = 16.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

class _TestCard extends StatelessWidget {
  const _TestCard(this.test);

  final LabTestType test;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Tokens.blueTint, borderRadius: BorderRadius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(test.code, Tokens.blueText),
        const SizedBox(height: 12),
        Text(test.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tokens.slate900)),
        const SizedBox(height: 6),
        Text(test.description ?? '', style: const TextStyle(color: Tokens.muted, fontSize: 13, height: 1.5)),
        if (test.defaultUnit != null) ...[
          const SizedBox(height: 10),
          Text('Unidad: ${test.defaultUnit}', style: const TextStyle(color: Tokens.slate500, fontSize: 12)),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    decoration: BoxDecoration(color: Tokens.orangeTint, borderRadius: BorderRadius.circular(20)),
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
            const SizedBox(width: 18),
            FilledButton(onPressed: onBook, child: const Text('Reservar')),
          ],
        ),
      ],
    ),
  );
}
