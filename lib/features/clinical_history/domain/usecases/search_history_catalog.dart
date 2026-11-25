import '../entities/patient_history.dart';
import '../repositories/patient_history_repository.dart';

/// Items of a catalog the patient picks from: allergens, vaccines or CIE-11 codes.
class SearchHistoryCatalog {
  const SearchHistoryCatalog(this._repository);

  final PatientHistoryRepository _repository;

  Future<List<CatalogOption>> call(String catalog, {String? query}) => _repository.catalog(catalog, query: query);
}
