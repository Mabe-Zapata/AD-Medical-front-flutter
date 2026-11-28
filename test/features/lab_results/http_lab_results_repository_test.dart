import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/lab_results/data/repositories/http_lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

const _orderId = '99999999-8888-4777-8666-555555555555';
const _otherId = '11111111-2222-4333-8444-555555555555';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// The listing answers [listed] ids; [forbidden] ids cannot be read, like an order of someone else.
HttpLabResultsRepository _repo({
  List<String> listed = const [_orderId],
  Set<String> forbidden = const {},
  List<Uri>? seen,
}) => HttpLabResultsRepository(
  ApiClient(
    baseUrl: 'http://api.test/api/v1',
    token: () => 'jwt',
    client: MockClient((request) async {
      seen?.add(request.url);
      final path = request.url.path;
      if (path == '/api/v1/lab/orders') {
        return _json({
          'items': [
            for (final id in listed)
              {
                'id': id,
                'paciente_id': 'patient-row-id',
                'estado': 'EN_PROCESO',
                'fecha': '2026-11-10T16:30:59Z',
              },
          ],
        }, 200);
      }
      final id = path.split('/')[5];
      if (forbidden.contains(id)) return _json({'detail': 'no'}, 403);
      if (path.endsWith('/results')) {
        return _json({
          'items': [
            {
              'id': 'r1',
              'detalle_id': 'd1',
              'nombre_analito': 'Hemoglobina',
              'unidad': 'g/dL',
              'valor_numerico': 14.2,
              'valor_texto': null,
              'referencia_min': 12.0,
              'referencia_max': 16.0,
              'interpretacion': 'DENTRO_REFERENCIA',
              'interpretacion_sistema': 'ALTO',
              'revisado': true,
              'corregido': true,
              'motivo_correccion': 'Lectura corregida por el laboratorio',
            },
            {
              'id': 'r2',
              'detalle_id': 'd1',
              'nombre_analito': 'Hematocrito',
              'unidad': '%',
              'valor_numerico': null,
              'valor_texto': 'normal',
            },
          ],
        }, 200);
      }
      return _json({
        'id': id,
        'paciente_id': 'patient-row-id',
        'prioridad': 'URGENTE',
        'estado': 'EN_PROCESO',
        'observaciones': 'ayuno',
        'pruebas': [
          {'detalle_id': 'd1', 'estado': 'COMPLETADO', 'tipo_prueba_id': 't1'},
          {'detalle_id': 'd2', 'estado': 'PENDIENTE', 'tipo_prueba_id': 't2'},
        ],
      }, 200);
    }),
  ),
);

void main() {
  _pdfTests();

  test(
    'lists the patient\'s orders and joins each one with its results',
    () async {
      final orders = await _repo().ordersOf('u1');

      final order = orders.single;
      expect(order.id, _orderId);
      // The app identifies the patient by the user id, not by the API's patient row.
      expect(order.patientId, 'u1');
      expect(order.priority, OrderPriority.urgent);
      expect(order.status, OrderStatus.inProgress);
      expect(order.doctorName, isNull);
      // The date comes from the listing, since the detail does not carry it.
      expect(order.orderedAt, DateTime.utc(2026, 11, 10, 16, 30, 59));
      expect(order.details.map((d) => d.status), [
        DetailStatus.completed,
        DetailStatus.pending,
      ]);
      expect(order.details.first.results.map((r) => r.name), [
        'Hemoglobina',
        'Hematocrito',
      ]);
      expect(order.details.first.results.first.valueNumeric, 14.2);
      expect(order.details.first.results.last.valueText, 'normal');
      expect(order.details.last.results, isEmpty);
    },
  );

  test('asks only for the newest orders, and keeps the API order', () async {
    final seen = <Uri>[];
    final orders = await _repo(
      listed: [_orderId, _otherId],
      seen: seen,
    ).ordersOf('u1');

    expect(seen.first.queryParameters['limit'], '20');
    expect(orders.map((o) => o.id), [_orderId, _otherId]);
  });

  test('an order that cannot be read does not hide the others', () async {
    final orders = await _repo(
      listed: [_orderId, _otherId],
      forbidden: {_orderId},
    ).ordersOf('u1');

    expect(orders.map((o) => o.id), [_otherId]);
  });

  test('a result carries its validated reference range and classification', () async {
    final result = (await _repo().ordersOf('u1')).single.details.first.validatedResults.first;

    expect((result.referenceMin, result.referenceMax), (12.0, 16.0));
    expect(result.interpretation, Interpretation.withinReference);
  });

  test('a corrected reading is flagged, and the reading the patient sees is the corrected one', () async {
    final results = (await _repo().ordersOf('u1')).single.details.first.validatedResults;

    expect(results.first.corrected, isTrue);
    expect(results.first.interpretation, Interpretation.withinReference);
    expect(results.last.corrected, isFalse);
  });

  test('no orders is an empty list', () async {
    expect(await _repo(listed: const []).ordersOf('u1'), isEmpty);
  });
}

void _pdfTests() {
  test('the results PDF of an order is downloaded with the bearer token and its bytes kept', () async {
    late Uri asked;
    late String? authorization;
    final repository = HttpLabResultsRepository(
      ApiClient(
        baseUrl: 'http://api.test/api/v1',
        token: () => 'jwt',
        client: MockClient((request) async {
          asked = request.url;
          authorization = request.headers['Authorization'];
          return http.Response.bytes(
            utf8.encode('%PDF-1.4 sample'),
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }),
      ),
    );

    final bytes = await repository.resultsReport(_orderId);

    expect(asked.path, '/api/v1/lab/orders/$_orderId/report.pdf');
    expect(authorization, 'Bearer jwt');
    expect(utf8.decode(bytes), startsWith('%PDF-'));
  });
}
