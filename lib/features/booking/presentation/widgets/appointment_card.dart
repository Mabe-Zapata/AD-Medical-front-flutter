import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';

(String, Color) _statusLabel(AppointmentStatus status) => switch (status) {
  AppointmentStatus.pendingPayment => ('Pago pendiente', Tokens.warning),
  AppointmentStatus.confirmed => ('Confirmada', Tokens.success),
  AppointmentStatus.completed => ('Completada', Tokens.muted),
  AppointmentStatus.cancelled => ('Cancelada', Tokens.danger),
  AppointmentStatus.expired => ('Expirada', Tokens.muted),
  AppointmentStatus.noShow => ('No asistió', Tokens.danger),
};

/// Presentational: one appointment as a card. A colored edge says its state at a glance, the blue panel holds
/// the date, the time and the payment, and the actions are only the ones that make sense for that state.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard(
    this.appointment, {
    super.key,
    this.onCancel,
    this.onPay,
    this.processing = false,
  });

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
    final (label, color) = _statusLabel(a.status);
    final start = branchTime(a.slot.startUtc);
    final expires = a.reservationExpiresAt;
    final pending = a.status == AppointmentStatus.pendingPayment;
    final inProcess = pending && processing;
    final price = a.service.basePrice > 0
        ? money(a.service.basePrice, a.service.currency)
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        // On a wide card the date sits left, the payment state right, and the actions end the row.
        final wide = constraints.maxWidth >= 640;
        final actions = [
          if (onPay != null && pending && !inProcess)
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Pagar ahora'),
            ),
          if (onCancel != null && a.holdsSlot && !inProcess)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: Tokens.danger),
              child: const Text('Cancelar cita'),
            ),
        ];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
            border: Border.all(color: Tokens.slate200),
            boxShadow: [
              BoxShadow(
                color: Tokens.blueDeep.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Tokens.blueTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'LABORATORIO CLÍNICO',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Tokens.blueText,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              'Ref: ${_shortId(a.id)}',
                              style: const TextStyle(
                                color: Tokens.muted,
                                fontSize: 12,
                              ),
                            ),
                            StatusChip(label, color),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          a.service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Tokens.slate900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Tokens.blueTint,
                            borderRadius: BorderRadius.circular(
                              Tokens.radiusSm + 4,
                            ),
                          ),
                          child: _panelContent(
                            wide: wide,
                            when: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _DateBlock(start),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeLabel(start),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: Tokens.slate900,
                                      ),
                                    ),
                                    Text(
                                      'Duración: ${a.service.durationMin} min',
                                      style: const TextStyle(
                                        color: Tokens.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            payment:
                                (pending ||
                                    a.status == AppointmentStatus.confirmed)
                                ? Column(
                                    crossAxisAlignment: wide
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ESTADO DEL PAGO',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Tokens.blueText,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (inProcess)
                                        const StatusChip(
                                          'En procesamiento',
                                          Tokens.info,
                                        )
                                      else if (pending)
                                        StatusChip(
                                          price == null
                                              ? 'Pendiente'
                                              : 'Pendiente: $price',
                                          Tokens.warning,
                                        )
                                      else
                                        const StatusChip(
                                          'Pagada',
                                          Tokens.success,
                                        ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        if (a.reason != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.notes_outlined,
                                size: 16,
                                color: Tokens.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a.reason!,
                                  style: const TextStyle(
                                    color: Tokens.slate600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (inProcess) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Tokens.blueTint,
                              borderRadius: BorderRadius.circular(
                                Tokens.radiusSm + 2,
                              ),
                              border: Border.all(color: Tokens.blueSoft),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 18,
                                  color: Tokens.blueText,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Pago pendiente de procesamiento. Tu cita se confirmará en cuanto el banco avise.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Tokens.blueText,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (pending && expires != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Tokens.orangeTint,
                              borderRadius: BorderRadius.circular(
                                Tokens.radiusSm + 2,
                              ),
                              border: Border.all(color: Tokens.orangeSoft),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: Tokens.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Retenida hasta las ${timeLabel(branchTime(expires))}. Págala antes para no perder el horario.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Tokens.slate700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: wide
                                  ? WrapAlignment.end
                                  : WrapAlignment.start,
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              // Primary action first on a phone, last (right edge) on a wide card.
                              children: wide
                                  ? actions.reversed.toList()
                                  : actions,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _panelContent({
    required bool wide,
    required Widget when,
    Widget? payment,
  }) => wide
      ? Row(children: [when, const Spacer(), ?payment])
      : Wrap(
          spacing: 28,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [when, ?payment],
        );

  /// A listed appointment has a long UUID; people recognize the first characters, not the whole code.
  static String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
}

class _DateBlock extends StatelessWidget {
  const _DateBlock(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Tokens.blueSoft),
    ),
    child: Column(
      children: [
        Text(
          weekdayLabel(date).toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Tokens.blueText,
          ),
        ),
        Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Tokens.slate900,
            height: 1.1,
          ),
        ),
        Text(
          monthLabel(date).toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Tokens.blueText,
          ),
        ),
      ],
    ),
  );
}
