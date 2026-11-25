import '../entities/patient_history.dart';
import '../repositories/patient_history_repository.dart';

/// One page of the history's event log, newest first.
class ReadHistoryEvents {
  const ReadHistoryEvents(this._repository);

  final PatientHistoryRepository _repository;

  Future<HistoryEventPage> call({required DateSpan span, required int limit, required int offset}) =>
      _repository.events(span: span, limit: limit, offset: offset);
}
