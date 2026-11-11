import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/payment_card_view.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/status_chip.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

/// Presentational: the "Pagos" area of the portal. Shows the default card, or says honestly that there is
/// none (the backend cannot keep cards yet).
class PaymentMethodsSection extends StatelessWidget {
  const PaymentMethodsSection({
    super.key,
    required this.card,
    required this.holderName,
    required this.demo,
    this.onRemove,
  });

  final SavedCard? card;
  final String holderName;

  /// True when the card is made up for the demo, so the screen says so.
  final bool demo;

  /// Asks to remove the saved card; null while another action is running.
  final VoidCallback? onRemove;

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
              if (saved != null)
                saved.isExpired(DateTime.now()) ? const StatusChip('VENCIDA', Tokens.danger) : const StatusChip('ACTIVA', Tokens.success),
            ],
          ),
          const Divider(height: 32),
          if (saved == null)
            const _Empty()
          else ...[
            Center(child: PaymentCardView(card: saved, holderName: holderName)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Tokens.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    saved.isExpired(DateTime.now()) ? 'VENCIDA: PAGA CON OTRA TARJETA' : 'PREDETERMINADA PARA COMPRAS RÁPIDAS',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Tokens.slate700),
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
          if (saved != null)
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Quitar tarjeta'),
              style: OutlinedButton.styleFrom(foregroundColor: Tokens.danger, side: const BorderSide(color: Tokens.danger)),
            ),
          if (saved != null) const SizedBox(height: 8),
          const Text(
            'Puedes guardar una tarjeta al pagar una cita, con la casilla "Guardar esta tarjeta". Guardar una nueva reemplaza la anterior.',
            style: TextStyle(fontSize: 12, color: Tokens.muted, height: 1.4),
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
      'Aún no tienes una tarjeta guardada.',
      style: TextStyle(fontSize: 14, color: Tokens.slate600, height: 1.5),
    ),
  );
}
