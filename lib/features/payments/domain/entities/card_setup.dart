/// What the backend gives back to save a card without paying: the SetupIntent's client secret and the public key
/// the browser needs to mount Stripe's card form. Neither can move money.
class CardSetup {
  const CardSetup({required this.clientSecret, required this.publishableKey});

  final String clientSecret;
  final String publishableKey;
}
