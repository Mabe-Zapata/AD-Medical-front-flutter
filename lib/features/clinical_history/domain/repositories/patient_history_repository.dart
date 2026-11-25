import '../entities/patient_history.dart';

/// Port to the patient's clinical history. Implementations throw `AppError`.
abstract class PatientHistoryRepository {
  /// The signed-in patient's history, limited to a range of days when one is given.
  Future<PatientHistory> read(DateSpan span);

  /// The event log of that history, newest first, one page at a time.
  Future<HistoryEventPage> events({required DateSpan span, required int limit, required int offset});

  /// Declares an entry about the patient. The patient id comes from the history that was read.
  Future<void> declare(String patientId, Declaration declaration);

  /// Items of a catalog. `catalog` is the backend's path name: cie11, vacunas or sustancias-alergia.
  Future<List<CatalogOption>> catalog(String catalog, {String? query});
}
