import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/repositories/catalog_repository.dart';

/// Serves a fixed catalog. The backend has no catalog endpoint yet, so the branches and the tests
/// are marketing content kept in the app and the bookable services come from build settings.
class StaticCatalogRepository implements CatalogRepository {
  const StaticCatalogRepository(this._catalog);

  final Catalog _catalog;

  @override
  Future<Catalog> fetchCatalog() async => _catalog;
}
