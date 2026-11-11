import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';

/// The backend has no endpoint for saved cards: payments go through Stripe Checkout and the card is never
/// stored on our side. Until it offers one (Stripe customers and payment methods), there is nothing to show,
/// and nothing is invented.
class HttpSavedCardRepository implements SavedCardRepository {
  const HttpSavedCardRepository();

  @override
  Future<SavedCard?> defaultCard(String patientId) async => null;
}
