import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';

class RemoveSavedCard {
  const RemoveSavedCard(this._repository);

  final SavedCardRepository _repository;

  Future<void> call(String patientId) => _repository.remove(patientId);
}
