import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/date_block.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';

(String, Color) appointmentStatusLabel(AppointmentStatus status) => switch (status) {
  AppointmentStatus.pendingPayment => ('Pago pendiente', Tokens.warning),
  AppointmentStatus.confirmed => ('Confirmada', Tokens.success),
  AppointmentStatus.completed => ('Completada', Tokens.muted),
  AppointmentStatus.cancelled => ('Cancelada', Tokens.danger),
  AppointmentStatus.expired => ('Expirada', Tokens.muted),
  AppointmentStatus.noShow => ('No asistió', Tokens.danger),
};

/// A short, recognizable reference: a listed appointment has a long UUID.
String appointmentRef(String id) => id.length > 8 ? id.substring(0, 8).toUpperCase() : id;

/// Presentational: one appointment as a compact row (date tile, what and when, state), with the actions that make
/// sense for that state underneath on a phone and at the end of the row on a wide screen.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard(this.appointment, {super.key, this.onCancel, this.onPay, this.processing = false});

  final Appointment appointment;

  /// The payment was sent and the bank has not confirmed it yet: no pay or cancel buttons, a notice instead.
  final bool processing;

  /// Shown only while the appointment still holds its slot.
  final VoidCallback? onCancel;

  /// Shown only while the appointment waits for payment.
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final pending = a.status == AppointmentStatus.pendingPayment;
    final inProcess = pending && processing;
    final (label, color) = inProcess ? ('Procesando pago', Tokens.info) : appointmentStatusLabel(a.status);
    final start = branchTime(a.slot.startUtc);
    final expires = a.reservationExpiresAt;
    final price = a.service.basePrice > 0 ? money(a.service.basePrice, a.service.currency) : null;
    final details = [
      '${timeLabel(start)} · ${a.service.durationMin} min',
      ?price,
      if (a.status == AppointmentStatus.confirmed) 'Pagada',
      if (a.reason != null) a.reason!,
      'Ref: ${appointmentRef(a.id)}',
    ].join(' · ');
    final actions = [
      if (onPay != null && pending && !inProcess)
        FilledButton.icon(onPressed: onPay, icon: const Icon(Icons.lock_outline, size: 18), label: const Text('Pagar ahora')),
      if (onCancel != null && a.holdsSlot && !inProcess)
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(foregroundColor: Tokens.danger),
          child: const Text('Cancelar cita'),
        ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        border: Border.all(color: Tokens.slate200),
        boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.service.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Tokens.slate900)),
              const SizedBox(height: 2),
              Text(details, style: const TextStyle(fontSize: 13, color: Tokens.muted)),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DateBlock(start),
                  const SizedBox(width: 16),
                  Expanded(child: info),
                  if (wide) ...[
                    const SizedBox(width: 12),
                    StatusChip(label, color),
                    for (final action in actions) ...[const SizedBox(width: 8), action],
                  ],
                ],
              ),
              if (!wide) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [StatusChip(label, color), ...actions]),
              ],
              if (inProcess) ...[
                const SizedBox(height: 12),
                const _Notice(
                  icon: Icons.hourglass_top_rounded,
                  text: 'Pago pendiente de procesamiento. Tu cita se confirmará en cuanto el banco avise.',
                  background: Tokens.blueTint,
                  border: Tokens.blueSoft,
                  foreground: Tokens.blueText,
                  bold: true,
                ),
              ] else if (pending && expires != null) ...[
                const SizedBox(height: 12),
                _Notice(
                  icon: Icons.timer_outlined,
                  text: 'Retenida hasta las ${timeLabel(branchTime(expires))}. Págala antes para no perder el horario.',
                  background: Tokens.orangeTint,
                  border: Tokens.orangeSoft,
                  foreground: Tokens.slate700,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.background, required this.border, required this.foreground, this.bold = false});

  final IconData icon;
  final String text;
  final Color background;
  final Color border;
  final Color foreground;
  final bool bold;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
    child: Row(
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: foreground, height: 1.4, fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ],
    ),
  );
}
