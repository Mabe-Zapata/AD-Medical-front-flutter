import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';

/// Port: the patient's saved card, or null when there is none. A card is saved by paying with the consent
/// box ticked; saving a new one replaces the old.
abstract interface class SavedCardRepository {
  Future<SavedCard?> defaultCard(String patientId);

  Future<void> remove(String patientId);
}
