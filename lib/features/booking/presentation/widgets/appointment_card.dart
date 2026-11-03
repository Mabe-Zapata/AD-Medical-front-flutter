import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

(String, Color) _statusLabel(AppointmentStatus status) => switch (status) {
  AppointmentStatus.pendingPayment => ('Pago pendiente', Tokens.warning),
  AppointmentStatus.confirmed => ('Confirmada', Tokens.success),
  AppointmentStatus.completed => ('Completada', Tokens.muted),
  AppointmentStatus.cancelled => ('Cancelada', Tokens.danger),
  AppointmentStatus.expired => ('Expirada', Tokens.muted),
  AppointmentStatus.noShow => ('No asistió', Tokens.danger),
};

class AppointmentCard extends StatelessWidget {
  const AppointmentCard(this.appointment, {super.key, this.onCancel});

  final Appointment appointment;

  /// Shown only while the appointment still holds its slot.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final (label, color) = _statusLabel(a.status);
    final expires = a.reservationExpiresAt;
    return Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: Tokens.brandGradient, borderRadius: BorderRadius.circular(Tokens.radiusSm + 4)),
            child: const Icon(Icons.event_available_outlined, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.service.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Tokens.slate900)),
                const SizedBox(height: 2),
                Text(
                  '${dateTimeLabel(branchTime(a.slot.startUtc))} · ${a.service.durationMin} min · ${a.id}',
                  style: const TextStyle(color: Tokens.muted, fontSize: 12),
                ),
                if (a.reason != null) ...[
                  const SizedBox(height: 6),
                  Text(a.reason!, style: const TextStyle(color: Tokens.slate600, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusChip(label, color),
                    if (a.status == AppointmentStatus.pendingPayment && expires != null)
                      StatusChip('Retenida hasta las ${timeLabel(branchTime(expires))}', Tokens.warning),
                  ],
                ),
                if (onCancel != null && a.holdsSlot) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Tokens.danger,
                      side: const BorderSide(color: Tokens.danger),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Cancelar cita'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
