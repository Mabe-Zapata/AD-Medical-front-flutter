import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

abstract interface class CatalogRepository {
  Future<Catalog> fetchCatalog();
}
