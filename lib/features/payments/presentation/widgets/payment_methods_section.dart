import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/payment_card_view.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

/// Presentational: the "Pagos" area of the portal. Shows the default card, or says honestly that there is
/// none (the backend cannot keep cards yet).
class PaymentMethodsSection extends StatelessWidget {
  const PaymentMethodsSection({super.key, required this.card, required this.holderName, required this.demo});

  final SavedCard? card;
  final String holderName;

  /// True when the card is made up for the demo, so the screen says so.
  final bool demo;

  static const _soon = 'Disponible cuando el servidor permita guardar tarjetas.';

  @override
  Widget build(BuildContext context) {
    final saved = card;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Tokens.orangeTint, borderRadius: BorderRadius.circular(Tokens.radiusSm)),
                child: const Icon(Icons.credit_card_outlined, color: Tokens.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarjeta guardada', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Tokens.slate900)),
                    Text('Método de pago predeterminado', style: TextStyle(fontSize: 13, color: Tokens.muted)),
                  ],
                ),
              ),
              if (saved != null) const StatusChip('ACTIVA', Tokens.success),
            ],
          ),
          const Divider(height: 32),
          if (saved == null)
            const _Empty()
          else ...[
            Center(child: PaymentCardView(card: saved, holderName: holderName)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Tokens.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PREDETERMINADA PARA COMPRAS RÁPIDAS',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Tokens.slate700),
                  ),
                ),
              ],
            ),
            if (demo) ...[
              const SizedBox(height: 8),
              const Text('Tarjeta de ejemplo de la versión demo.', style: TextStyle(fontSize: 12, color: Tokens.muted)),
            ],
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Tooltip(
                message: _soon,
                child: OutlinedButton.icon(onPressed: null, icon: Icon(Icons.add_card_outlined, size: 18), label: Text('Agregar tarjeta')),
              ),
              Tooltip(
                message: _soon,
                child: OutlinedButton.icon(onPressed: null, icon: Icon(Icons.settings_outlined, size: 18), label: Text('Gestionar')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Tokens.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Los pagos los procesa Stripe en una página segura. Medilo nunca ve ni guarda el número de tu tarjeta.',
                  style: TextStyle(fontSize: 12, color: Tokens.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Aún no tienes una tarjeta guardada. Por ahora pagas cada cita en la página segura de Stripe.',
      style: TextStyle(fontSize: 14, color: Tokens.slate600, height: 1.5),
    ),
  );
}
