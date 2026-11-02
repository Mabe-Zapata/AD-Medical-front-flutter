import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/repositories/catalog_repository.dart';

class GetCatalog {
  const GetCatalog(this._repository);

  final CatalogRepository _repository;

  Future<Catalog> call() => _repository.fetchCatalog();
}
