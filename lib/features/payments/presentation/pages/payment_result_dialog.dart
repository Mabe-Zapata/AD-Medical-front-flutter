import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Where the payment provider sends the patient back (`/pago/exito`, `/pago/cancelado`).
///
/// Coming back never proves the payment: the backend marks it paid only when the provider's signed
/// notification arrives, so the success copy says "estamos confirmando", never "pagado".
class PaymentResultDialog extends StatelessWidget {
  const PaymentResultDialog({super.key, required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) => TwoPanelModal(
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
          decoration: BoxDecoration(
            color: (completed ? Tokens.success : Tokens.warning).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed ? Icons.hourglass_top_rounded : Icons.info_outline,
            color: completed ? Tokens.success : Tokens.warning,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          completed ? 'Estamos confirmando tu pago' : 'Cancelaste el pago',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 12),
        Text(
          completed
              ? 'Tu cita pasará a "Confirmada" en cuanto llegue la confirmación del banco. Suele tardar unos segundos.'
              : 'No se cobró nada. Tu cita sigue reservada hasta que venza la retención; puedes pagarla desde tu portal.',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
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
