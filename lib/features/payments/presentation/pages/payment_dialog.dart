import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/payment_source.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/policies/payment_failure.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: pays for an appointment inside the portal. It loads the saved card, holds the summary and the
/// card form (drawn by [AppDependencies.embeddedCheckout]), sends the chosen [PaymentSource] and explains a
/// failure in Spanish, keeping what the patient chose. When the payment is sent it closes with `true`; sending
/// it never proves the payment: only the backend's signed webhook confirms it.
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key, required this.appointment, required this.checkout});

  final Appointment appointment;
  final Embedded checkout;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  Future<SavedCard?>? _card;
  bool _sent = false;
  bool _busy = false;
  String? _error;
  bool _cardProblem = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = AppScope.of(context);
    final patient = deps.session.patient;
    // If the saved card cannot be read, the form falls back to a new card.
    _card ??= patient == null ? Future.value() : deps.getSavedCard(patient.id).catchError((_) => null);
  }

  Future<void> _submit(PaymentSource source) async {
    final deps = AppScope.of(context);
    final patient = deps.session.patient;
    if (patient == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await deps.payWithCard?.call(patientId: patient.id, appointmentId: widget.appointment.id, source: source);
      if (mounted) setState(() => _sent = true);
    } on AppError catch (error) {
      if (mounted) {
        setState(() {
          _error = paymentFailureMessage(error);
          _cardProblem = paymentFailureIsTheCard(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    // A price of zero means the listing did not say which service it was.
    final amount = a.service.basePrice > 0 ? money(a.service.basePrice, a.service.currency) : null;
    return TwoPanelModal(
      tag: 'Pago de tu cita',
      headline: 'Paga sin salir de Medilo.',
      bullets: const [
        'El campo de tarjeta es de Stripe: Medilo nunca ve tu número.',
        'Tu cita se confirma cuando el banco avisa el pago.',
        'Mientras tanto, tu horario sigue retenido.',
      ],
      footerLabel: 'Pago en línea',
      footerNote: 'Cifrado',
      child: _sent
          ? _Sent(onClose: () => Navigator.of(context).pop(true))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pagar cita',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
                ),
                const SizedBox(height: 12),
                Text(a.service.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate900)),
                Text(
                  amount == null
                      ? dateTimeLabel(branchTime(a.slot.startUtc))
                      : '${dateTimeLabel(branchTime(a.slot.startUtc))} · $amount',
                  style: const TextStyle(color: Tokens.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FutureBuilder<SavedCard?>(
                  future: _card,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
                      );
                    }
                    return AppScope.of(context).embeddedCheckout(
                      context,
                      checkout: widget.checkout,
                      amountLabel: amount,
                      savedCard: snapshot.data,
                      busy: _busy,
                      error: _error,
                      errorIsTheCard: _cardProblem,
                      onSubmit: _submit,
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _Sent extends StatelessWidget {
  const _Sent({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Tokens.success.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.hourglass_top_rounded, color: Tokens.success, size: 28),
      ),
      const SizedBox(height: 18),
      const Text(
        'Pago enviado',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 12),
      const Text(
        'Estamos confirmando tu pago. Tu cita pasará a "Confirmada" en cuanto llegue la confirmación del banco.',
        style: TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: 'Volver a mi portal', trailing: Icons.arrow_forward, onPressed: onClose),
      ),
    ],
  );
}
