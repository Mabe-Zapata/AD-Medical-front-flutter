import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Where the payment provider sends the patient back (`/pago/exito`, `/pago/retorno`, `/pago/cancelado`).
///
/// Coming back never proves the payment, so a completed return asks the backend for the latest attempt of this run.
/// Only a confirmed payment reads as paid. Anything else (still unconfirmed, rejected, or unreadable) says that an
/// error happened and the payment was not completed.
class PaymentResultDialog extends StatefulWidget {
  const PaymentResultDialog({super.key, required this.completed});

  final bool completed;

  @override
  State<PaymentResultDialog> createState() => _PaymentResultDialogState();
}

class _PaymentResultDialogState extends State<PaymentResultDialog> {
  Future<CheckoutStatus?>? _latest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_latest != null || !widget.completed) return;
    final deps = AppScope.of(context);
    final patient = deps.session.patient;
    _latest = patient == null
        ? Future.value()
        : deps.getLatestCheckout(patientId: patient.id).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.completed) {
      return _frame(
        icon: Icons.info_outline,
        tone: Tokens.warning,
        title: 'Cancelaste el pago',
        body: 'No se cobró nada. Tu cita sigue reservada hasta que venza la retención; puedes pagarla desde tu portal.',
      );
    }
    return FutureBuilder<CheckoutStatus?>(
      future: _latest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _frame(
            icon: Icons.hourglass_top_rounded,
            tone: Tokens.warning,
            title: 'Estamos verificando tu pago',
            body: 'Un momento, estamos revisando con el banco si el pago se completó.',
          );
        }
        if (snapshot.data?.state == CheckoutState.confirmed) {
          return _frame(
            icon: Icons.check_circle_outline,
            tone: Tokens.success,
            title: 'Pago confirmado',
            body: 'Tu pago está confirmado. El laboratorio confirmará tu cita.',
          );
        }
        return _frame(
          icon: Icons.error_outline,
          tone: Tokens.danger,
          title: 'Ocurrió un error',
          body:
              'El pago no se ha completado. Tu cita sigue reservada hasta que venza la retención; '
              'puedes intentar pagarla de nuevo desde tu portal.',
        );
      },
    );
  }

  Widget _frame({required IconData icon, required Color tone, required String title, required String body}) =>
      TwoPanelModal(
        tag: 'Pago de tu cita',
        headline: 'Pagos seguros con Stripe.',
        bullets: const [
          'Medilo no ve ni guarda los datos de tu tarjeta.',
          'Tu cita se confirma cuando el banco avisa el pago.',
          'Mientras tanto, tu horario sigue retenido.',
        ],
        footerLabel: 'Pago en línea',
        footerNote: 'Cifrado',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: tone, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
            ),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Ir a mi portal',
                trailing: Icons.arrow_forward,
                onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.portal),
              ),
            ),
          ],
        ),
      );
}
