import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/repositories/catalog_repository.dart';

/// Reads the bookable services from `GET /services` (the live catalog of the backend).
///
/// `GET /services` requires a session, and the public landing page loads before any sign-in, so
/// without a session the services list is empty instead of calling the API. Branches and lab test
/// types stay as marketing content from [fallback].
class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(
    this._api, {
    required this.isSignedIn,
    required this.fallback,
  });

  final ApiClient _api;
  final bool Function() isSignedIn;
  final Catalog fallback;

  @override
  Future<Catalog> fetchCatalog() async {
    if (!isSignedIn()) {
      return Catalog(branches: fallback.branches, services: const [], testTypes: fallback.testTypes);
    }
    final json = await _api.get('/services') as Map<String, dynamic>;
    return Catalog(
      branches: fallback.branches,
      services: [for (final item in json['items'] as List) _service(item as Map<String, dynamic>)],
      testTypes: fallback.testTypes,
    );
  }

  MedicalService _service(Map<String, dynamic> json) => MedicalService(
    id: json['id'] as String,
    name: json['nombre'] as String,
    durationMin: json['duracion_min'] as int,
    basePrice: double.parse(json['precio_base'].toString()),
    currency: json['moneda'] as String,
    specialtyId: json['especialidad_id'] as int?,
    requiresOrder: json['requiere_orden_medica'] as bool,
  );
}
