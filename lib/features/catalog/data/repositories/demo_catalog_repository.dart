import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoCatalogRepository implements CatalogRepository {
  const DemoCatalogRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<Catalog> fetchCatalog() async {
    await _db.simulateLatency();
    return Catalog(branches: _db.branches, services: _db.services, testTypes: _db.testTypes);
  }
}
