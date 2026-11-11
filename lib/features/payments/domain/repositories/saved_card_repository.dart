import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';

/// Port: the patient's default card, or null when there is none.
abstract interface class SavedCardRepository {
  Future<SavedCard?> defaultCard(String patientId);
}
