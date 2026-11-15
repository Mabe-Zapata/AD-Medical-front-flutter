import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/stripe_card_setup.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/stripe_card_setup_controller.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';

/// Saves a card without paying. Closes with `true` once Stripe has stored it. The consent box is required: only then
/// the card may be offered again in later checkouts.
///
/// The body scrolls both ways, so nothing is cut at a small window. The save button lives in the footer and is always
/// visible; the Stripe form is an embedded frame, which does not pass the wheel to the page, so it is never the only
/// way to reach an action.
class SaveCardDialog extends StatefulWidget {
  const SaveCardDialog({super.key, required this.start});

  /// Asks the backend for a SetupIntent (through the controller, which knows the patient).
  final Future<CardSetup> Function() start;

  @override
  State<SaveCardDialog> createState() => _SaveCardDialogState();
}

class _SaveCardDialogState extends State<SaveCardDialog> {
  /// The narrowest the form can be drawn: below this the body scrolls sideways instead of squeezing the fields.
  static const _minContentWidth = 460.0;

  late final Future<CardSetup> _setup = widget.start();
  final _card = StripeCardSetupController();
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  bool _consented = false;

  @override
  void dispose() {
    _card.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // A fixed frame: header, a body that scrolls both ways, and a footer whose buttons are always on screen.
    final width = (size.width - 40).clamp(320.0, 520.0).toDouble();
    // Tall enough for the whole Stripe form in a normal window; a shorter window scrolls the body instead.
    final height = (size.height - 24).clamp(420.0, 700.0).toDouble();
    final contentWidth = (width - 48) < _minContentWidth ? _minContentWidth : width - 48;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Guardar una tarjeta',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Tokens.slate900),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Scrollbar(
                  controller: _vertical,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _vertical,
                    child: Scrollbar(
                      controller: _horizontal,
                      thumbVisibility: true,
                      notificationPredicate: (notification) => notification.depth == 1,
                      child: SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          child: ListenableBuilder(listenable: _card, builder: (context, _) => _body()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _card.busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                  ListenableBuilder(
                    listenable: _card,
                    builder: (context, _) => FilledButton(
                      onPressed: _consented && _card.canSave ? _card.save : null,
                      child: Text(_card.busy ? 'Guardando…' : 'Guardar tarjeta'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() => FutureBuilder<CardSetup>(
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
            onChanged: _card.busy ? null : (value) => setState(() => _consented = value ?? false),
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
            controller: _card,
            consented: _consented,
            onSaved: () => Navigator.of(context).pop(true),
          ),
          if (_card.error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(error: ErrorView(_card.error!)),
          ],
          const SizedBox(height: 16),
        ],
      );
    },
  );
}
