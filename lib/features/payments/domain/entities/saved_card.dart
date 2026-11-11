/// A card the patient keeps for quick payments. Only what is safe to show: the brand, the last four digits
/// and the expiry; the number itself never reaches the app. [id] is the provider's id of the card, used to remove it.
class SavedCard {
  const SavedCard({required this.id, required this.brand, required this.last4, this.expMonth, this.expYear});

  final String id;
  final String brand;
  final String last4;

  /// The provider may not know the expiry; then the card is never treated as expired.
  final int? expMonth;
  final int? expYear;

  /// A card is valid through the last day of its expiry month.
  bool isExpired(DateTime now) {
    final month = expMonth;
    final year = expYear;
    return month != null && year != null && !now.isBefore(DateTime(year, month + 1));
  }

  /// `09/28`, or `--/--` when unknown.
  String get expiry {
    final month = expMonth;
    final year = expYear;
    if (month == null || year == null) return '--/--';
    return '${month.toString().padLeft(2, '0')}/${(year % 100).toString().padLeft(2, '0')}';
  }
}
