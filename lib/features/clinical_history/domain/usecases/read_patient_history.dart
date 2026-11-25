import '../entities/patient_history.dart';
import '../repositories/patient_history_repository.dart';

/// The signed-in patient's history, limited to a range of days when one is given.
class ReadPatientHistory {
  const ReadPatientHistory(this._repository);

  final PatientHistoryRepository _repository;

  Future<PatientHistory> call(DateSpan span) => _repository.read(span);
}
