import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/stripe_card_setup.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';

/// Saves a card without paying. Closes with `true` once Stripe has stored it. The consent box is required: only then
/// the card may be offered again in later checkouts.
class SaveCardDialog extends StatefulWidget {
  const SaveCardDialog({super.key, required this.start});

  /// Asks the backend for a SetupIntent (through the controller, which knows the patient).
  final Future<CardSetup> Function() start;

  @override
  State<SaveCardDialog> createState() => _SaveCardDialogState();
}

class _SaveCardDialogState extends State<SaveCardDialog> {
  late final Future<CardSetup> _setup = widget.start();
  bool _consented = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Guardar una tarjeta'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: FutureBuilder<CardSetup>(
          future: _setup,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorBanner(error: describeError(snapshot.error!));
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckboxListTile(
                  value: _consented,
                  onChanged: (value) => setState(() => _consented = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: Tokens.blue,
                  title: const Text(
                    'Autorizo guardar esta tarjeta para mis próximas compras en Medilo. Puedo quitarla cuando quiera.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 8),
                stripeCardSetup(
                  context,
                  setup: snapshot.data!,
                  consented: _consented,
                  onSaved: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ),
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
  );
}
