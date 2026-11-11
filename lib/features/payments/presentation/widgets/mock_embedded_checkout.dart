import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/payment_source.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';

/// What draws the in-portal card form. The real one mounts Stripe's own card field (Stripe.js), turns what the
/// patient typed into a payment method id and hands it to [onSubmit]; until the backend can take that, a mock
/// stands in. The form never sees a card number: it only produces a [PaymentSource].
typedef EmbeddedCheckoutBuilder =
    Widget Function(
      BuildContext context, {
      required Embedded checkout,
      required String? amountLabel,
      required SavedCard? savedCard,
      required bool busy,
      required String? error,
      required bool errorIsTheCard,
      required void Function(PaymentSource source) onSubmit,
    });

/// What the API mode shows until Stripe's own form is mounted: it says so and charges nothing. A mock here would
/// pretend to take a payment that never happens.
Widget unavailableEmbeddedCheckout(
  BuildContext context, {
  required Embedded checkout,
  required String? amountLabel,
  required SavedCard? savedCard,
  required bool busy,
  required String? error,
  required bool errorIsTheCard,
  required void Function(PaymentSource source) onSubmit,
}) => const InfoBanner(
  message:
      'El formulario de pago de Stripe todavía no está integrado en el portal, así que no se cobró nada. Tu cita sigue reservada: inténtalo más adelante o contacta al laboratorio.',
  color: Tokens.warning,
  icon: Icons.construction_outlined,
);

/// Stripe's test cards, and the test payment method each one stands for.
const _testCards = <(String, String, String)>[
  ('Pago exitoso', '4242 4242 4242 4242', 'pm_card_visa'),
  ('Rechazo genérico', '4000 0000 0000 0002', 'pm_card_chargeDeclined'),
  ('Fondos insuficientes', '4000 0000 0000 9995', 'pm_card_chargeDeclinedInsufficientFunds'),
  ('Tarjeta vencida', '4000 0000 0000 0069', 'pm_card_chargeDeclinedExpiredCard'),
  ('Exige 3D Secure', '4000 0025 0000 3155', 'pm_card_threeDSecure2Required'),
];

/// Stand-in for Stripe's card field. Nobody types a number here on purpose: a mock must never collect real
/// card data, so the patient picks one of Stripe's test cards instead.
Widget mockEmbeddedCheckout(
  BuildContext context, {
  required Embedded checkout,
  required String? amountLabel,
  required SavedCard? savedCard,
  required bool busy,
  required String? error,
  required bool errorIsTheCard,
  required void Function(PaymentSource source) onSubmit,
}) => _MockForm(
  amountLabel: amountLabel,
  savedCard: savedCard,
  busy: busy,
  error: error,
  errorIsTheCard: errorIsTheCard,
  onSubmit: onSubmit,
);

class _MockForm extends StatefulWidget {
  const _MockForm({
    required this.amountLabel,
    required this.savedCard,
    required this.busy,
    required this.error,
    required this.errorIsTheCard,
    required this.onSubmit,
  });

  final String? amountLabel;
  final SavedCard? savedCard;
  final bool busy;
  final String? error;
  final bool errorIsTheCard;
  final void Function(PaymentSource source) onSubmit;

  @override
  State<_MockForm> createState() => _MockFormState();
}

class _MockFormState extends State<_MockForm> {
  static const _consent =
      'Al marcar esta casilla autorizas guardar tu tarjeta de forma segura con Stripe para tus próximas compras. Puedes quitarla cuando quieras desde tu portal.';

  bool _useOther = false;
  bool _save = false;
  int _test = 0;

  /// A saved card that has not expired is the default; an expired one is only informative.
  SavedCard? get _usable {
    final card = widget.savedCard;
    return card != null && !card.isExpired(DateTime.now()) ? card : null;
  }

  bool get _showingSaved => _usable != null && !_useOther;

  @override
  Widget build(BuildContext context) {
    final saved = widget.savedCard;
    final expired = saved != null && _usable == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoBanner(
          message: 'Simulación: aquí Stripe dibujará su campo de tarjeta seguro. No escribas datos reales.',
          color: Tokens.info,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 16),
        if (expired) ...[
          InfoBanner(
            message: 'Tu tarjeta guardada (${saved.brand} •••• ${saved.last4}) venció el ${saved.expiry}. Usa otra tarjeta.',
            color: Tokens.warning,
            icon: Icons.event_busy_outlined,
          ),
          const SizedBox(height: 16),
        ],
        if (_showingSaved) _savedRow(_usable!) else ..._newCard(),
        if (widget.error != null) ...[
          const SizedBox(height: 16),
          InfoBanner(message: widget.error!, color: Tokens.danger, icon: Icons.error_outline),
          if (_showingSaved && widget.errorIsTheCard)
            TextButton(onPressed: () => setState(() => _useOther = true), child: const Text('Usar otra tarjeta')),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: widget.busy ? 'Procesando…' : (widget.amountLabel == null ? 'Pagar' : 'Pagar ${widget.amountLabel}'),
            onPressed: widget.busy ? null : _submit,
          ),
        ),
      ],
    );
  }

  Widget _savedRow(SavedCard card) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Tokens.orangeTint,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      border: Border.all(color: Tokens.orangeSoft),
    ),
    child: Row(
      children: [
        const Icon(Icons.credit_card_outlined, color: Tokens.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pagar con ${card.brand} •••• ${card.last4} · vence ${card.expiry}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate900),
          ),
        ),
        TextButton(onPressed: () => setState(() => _useOther = true), child: const Text('Usar otra tarjeta')),
      ],
    ),
  );

  List<Widget> _newCard() => [
    DropdownButtonFormField<int>(
      initialValue: _test,
      decoration: const InputDecoration(labelText: 'Tarjeta de prueba de Stripe'),
      items: [for (var i = 0; i < _testCards.length; i++) DropdownMenuItem(value: i, child: Text(_testCards[i].$1))],
      onChanged: (value) => setState(() => _test = value ?? 0),
    ),
    const SizedBox(height: 12),
    TextFormField(
      key: ValueKey(_test),
      initialValue: _testCards[_test].$2,
      readOnly: true,
      decoration: const InputDecoration(labelText: 'Número de tarjeta', prefixIcon: Icon(Icons.credit_card_outlined, size: 20)),
    ),
    const SizedBox(height: 4),
    CheckboxListTile(
      value: _save,
      onChanged: (value) => setState(() => _save = value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Guardar esta tarjeta para próximas compras', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: const Text(_consent, style: TextStyle(fontSize: 12, height: 1.4, color: Tokens.muted)),
    ),
  ];

  void _submit() => widget.onSubmit(
    _showingSaved ? const SavedCardSource() : NewCardSource(_testCards[_test].$3, save: _save),
  );
}
