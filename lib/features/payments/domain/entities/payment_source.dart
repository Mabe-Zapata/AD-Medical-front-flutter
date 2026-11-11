/// Where the money comes from. Exactly one of the two, never both: the type makes any other
/// combination impossible to build.
sealed class PaymentSource {
  const PaymentSource();
}

/// A card typed into the payment provider's own field. The app only ever holds the id the provider made
/// for it ([paymentMethodId]), never the number. [save] is true only when the patient ticked the consent box.
final class NewCardSource extends PaymentSource {
  const NewCardSource(this.paymentMethodId, {this.save = false});

  final String paymentMethodId;
  final bool save;
}

/// The card the patient already saved.
final class SavedCardSource extends PaymentSource {
  const SavedCardSource();
}
