import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/stripe_card_setup_controller.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';

/// Outside the browser there is no Stripe.js: nothing is saved, the footer button stays disabled and the patient is
/// told so.
Widget stripeCardSetup(
  BuildContext context, {
  required CardSetup setup,
  required StripeCardSetupController controller,
  required bool consented,
  required VoidCallback onSaved,
}) => const InfoBanner(
  message: 'Guardar una tarjeta necesita el formulario de Stripe, que solo funciona en el navegador. No se guardó nada.',
  color: Tokens.warning,
  icon: Icons.construction_outlined,
);
