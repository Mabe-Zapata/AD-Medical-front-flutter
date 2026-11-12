import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/appointment_card.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/date_block.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';

/// Presentational: the appointment that comes first, large, with its main action. It sits over the blue band.
class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard(this.appointment, {super.key, this.onCancel, this.onPay, this.processing = false});

  final Appointment appointment;
  final bool processing;
  final VoidCallback? onCancel;
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
    final showPay = onPay != null && pending && !inProcess;
    final showCancel = onCancel != null && a.holdsSlot && !inProcess;
    final note = inProcess
        ? 'Pago pendiente de procesamiento. Tu cita se confirmará en cuanto el banco avise.'
        : (pending && expires != null ? 'Retenida hasta las ${timeLabel(branchTime(expires))}. Págala antes para no perder el horario.' : null);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('TU PRÓXIMA CITA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: Tokens.orangeDeep)),
            StatusChip(label, color),
          ],
        ),
        const SizedBox(height: 6),
        Text(a.service.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Tokens.slate900)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            _Fact(Icons.schedule, '${timeLabel(start)} · ${a.service.durationMin} min'),
            if (price != null) _Fact(Icons.credit_card_outlined, price),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: inProcess ? Tokens.blueTint : Tokens.orangeTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: inProcess ? Tokens.blueSoft : Tokens.orangeSoft),
            ),
            child: Text(note, style: TextStyle(fontSize: 12.5, color: inProcess ? Tokens.blueText : Tokens.slate700, fontWeight: inProcess ? FontWeight.w600 : FontWeight.w400)),
          ),
        ],
      ],
    );
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPay) FilledButton.icon(onPressed: onPay, icon: const Icon(Icons.lock_outline, size: 18), label: const Text('Pagar ahora')),
        if (showCancel)
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: Tokens.danger),
            child: const Text('Cancelar cita'),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Tokens.slate200),
        boxShadow: [
          BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.16), blurRadius: 48, offset: const Offset(0, 24)),
          BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final hasActions = showPay || showCancel;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DateBlock(start, filled: true),
                const SizedBox(width: 24),
                Expanded(child: info),
                if (hasActions) ...[const SizedBox(width: 24), SizedBox(width: 180, child: actions)],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [DateBlock(start, filled: true), const SizedBox(width: 16), Expanded(child: info)]),
              if (hasActions) ...[const SizedBox(height: 16), actions],
            ],
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Tokens.blue),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 14, color: Tokens.slate600)),
    ],
  );
}
