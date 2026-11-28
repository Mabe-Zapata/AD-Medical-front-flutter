/// What the backend gives back when a checkout is opened: where the patient pays.
sealed class CheckoutStart {
  const CheckoutStart();
}

/// Stripe's hosted page: the browser leaves the portal and comes back to `/pago/exito`.
final class RedirectTo extends CheckoutStart {
  const RedirectTo(this.page);

  final Uri page;
}

/// Stripe's form drawn inside the portal. [clientSecret] and [publishableKey] are meant for the browser
/// (they cannot move money); the secret key never leaves the server.
final class Embedded extends CheckoutStart {
  const Embedded({required this.clientSecret, required this.publishableKey});

  final String clientSecret;
  final String publishableKey;
}
