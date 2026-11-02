import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
    required this.service,
    required this.slot,
    required this.conflictedSlot,
    required this.submitting,
    required this.canConfirm,
    required this.holdMinutes,
    required this.onConfirm,
  });

  final MedicalService service;
  final TimeSlot? slot;
  final TimeSlot? conflictedSlot;
  final bool submitting;
  final bool canConfirm;
  final int holdMinutes;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final conflict = conflictedSlot;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tokens.slate900)),
          const SizedBox(height: 16),
          _Row('Servicio', service.name),
          _Row('Duración', '${service.durationMin} min'),
          _Row('Cuándo', slot == null ? 'Elige una hora' : dateTimeLabel(branchTime(slot!.startUtc))),
          const Divider(height: 28),
          _Row('Precio', money(service.basePrice, service.currency), bold: true),
          const SizedBox(height: 20),
          if (conflict != null) ...[
            InfoBanner(
              message: 'Otro paciente acaba de reservar las ${timeLabel(branchTime(conflict.startUtc))}. Elige otra hora.',
              color: Tokens.danger,
              icon: Icons.event_busy_outlined,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: submitting ? 'Verificando disponibilidad…' : 'Confirmar reserva',
              onPressed: canConfirm ? onConfirm : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'El horario se retiene $holdMinutes minutos. El pago es el siguiente paso de la '
            'plataforma y no forma parte de esta demo.',
            style: const TextStyle(fontSize: 12, color: Tokens.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Tokens.muted)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: bold ? 18 : 14,
              color: bold ? Tokens.orangeDeep : Tokens.slate900,
            ),
          ),
        ),
      ],
    ),
  );
}
