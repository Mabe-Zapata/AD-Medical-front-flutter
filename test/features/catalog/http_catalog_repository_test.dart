import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/catalog/data/repositories/http_catalog_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

const _fallback = Catalog(branches: [], services: [], testTypes: []);

http.Response _json(Object body) =>
    http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

HttpCatalogRepository _repo(MockClient client, {String? token}) => HttpCatalogRepository(
  ApiClient(client: client, baseUrl: 'http://api.test/api/v1', token: () => token),
  fallback: _fallback,
);

void main() {
  test('maps the active services of GET /public/services, including money as text', () async {
    late Uri seen;
    final repo = _repo(
      MockClient((request) async {
        seen = request.url;
        return _json({
          'items': [
            {
              'id': '6d5efc31-05d5-5ea7-9ec9-913ccfef48ea',
              'nombre': 'Consulta general',
              'duracion_min': 30,
              'precio_base': '25.00',
              'moneda': 'USD',
              'especialidad_id': null,
              'requiere_orden_medica': false,
            },
            {
              'id': 'fd38cc50-24ec-499f-83be-186d2864191e',
              'nombre': 'Revisión de resultados',
              'duracion_min': 20,
              'precio_base': '8.50',
              'moneda': 'USD',
              'especialidad_id': 3,
              'requiere_orden_medica': true,
            },
          ],
        });
      }),
    );

    final catalog = await repo.fetchCatalog();

    expect(seen.path, '/api/v1/public/services');
    expect(catalog.services.map((s) => s.name), ['Consulta general', 'Revisión de resultados']);
    expect(catalog.services.first.basePrice, 25);
    expect(catalog.services.first.needsDoctor, isFalse);
    expect(catalog.services.last.specialtyId, 3);
    expect(catalog.services.last.requiresOrder, isTrue);
  });

  test('a visitor without a session gets the services too: the landing loads before sign-in', () async {
    final paths = <String>[];
    final repo = _repo(
      MockClient((request) async {
        paths.add(request.url.path);
        return _json({
          'items': [
            {
              'id': 'fd38cc50-24ec-499f-83be-186d2864191e',
              'nombre': 'Toma de muestra de sangre',
              'duracion_min': 20,
              'precio_base': '8.00',
              'moneda': 'USD',
              'especialidad_id': null,
              'requiere_orden_medica': false,
            },
          ],
        });
      }),
    );

    final catalog = await repo.fetchCatalog();

    expect(paths, ['/api/v1/public/services']);
    expect(catalog.services.single.name, 'Toma de muestra de sangre');
  });
}
