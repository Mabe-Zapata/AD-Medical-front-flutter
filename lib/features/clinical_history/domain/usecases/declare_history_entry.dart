import '../entities/patient_history.dart';
import '../repositories/patient_history_repository.dart';

/// Declares an allergy, antecedent, medication or vaccine. The entry waits for a doctor's confirmation.
class DeclareHistoryEntry {
  const DeclareHistoryEntry(this._repository);

  final PatientHistoryRepository _repository;

  Future<void> call(String patientId, Declaration declaration) => _repository.declare(patientId, declaration);
}
