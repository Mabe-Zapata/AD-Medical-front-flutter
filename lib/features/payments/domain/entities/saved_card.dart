/// A card the patient keeps for quick payments. Only what is safe to show: the brand, the last four digits
/// and the expiry; the number itself never reaches the app.
class SavedCard {
  const SavedCard({required this.brand, required this.last4, required this.expMonth, required this.expYear});

  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
}
