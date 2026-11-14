import 'package:medicalbooking_portal/features/payments/presentation/widgets/mock_embedded_checkout.dart';

/// Outside the browser there is no Stripe.js: the portal says so and charges nothing.
const stripeEmbeddedCheckout = unavailableEmbeddedCheckout;
