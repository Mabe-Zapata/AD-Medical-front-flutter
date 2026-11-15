import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';

/// Starts saving a card without paying. The card is stored only when Stripe confirms the form in the browser.
class StartCardSetup {
  const StartCardSetup(this._repository);

  final SavedCardRepository _repository;

  Future<CardSetup> call(String patientId) => _repository.startSetup(patientId);
}
