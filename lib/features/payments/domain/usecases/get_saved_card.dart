import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';

class GetSavedCard {
  const GetSavedCard(this._repository);

  final SavedCardRepository _repository;

  Future<SavedCard?> call(String patientId) => _repository.defaultCard(patientId);
}
