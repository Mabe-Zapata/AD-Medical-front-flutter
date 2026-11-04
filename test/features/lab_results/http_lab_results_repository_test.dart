import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/lab_results/data/repositories/http_lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/lookup_lab_order.dart';

const _orderId = '99999999-8888-4777-8666-555555555555';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

HttpLabResultsRepository _repo({int orderStatus = 200}) => HttpLabResultsRepository(
  ApiClient(
    baseUrl: 'http://api.test/api/v1',
    token: () => 'jwt',
    client: MockClient((request) async {
      if (orderStatus != 200) return _json({'detail': 'no'}, orderStatus);
      if (request.url.path.endsWith('/results')) {
        return _json({
          'items': [
            {'id': 'r1', 'detalle_id': 'd1', 'nombre_analito': 'Hemoglobina', 'unidad': 'g/dL', 'valor_numerico': 14.2, 'valor_texto': null},
            {'id': 'r2', 'detalle_id': 'd1', 'nombre_analito': 'Hematocrito', 'unidad': '%', 'valor_numerico': null, 'valor_texto': 'normal'},
          ],
        }, 200);
      }
      return _json({
        'id': _orderId,
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
  test('joins the order with its results and keeps what the API does not send empty', () async {
    final order = await _repo().findOrder(patientId: 'u1', code: _orderId.toUpperCase());

    expect(order.id, _orderId);
    // The app identifies the patient by the user id, not by the API's patient row.
    expect(order.patientId, 'u1');
    expect(order.priority, OrderPriority.urgent);
    expect(order.status, OrderStatus.inProgress);
    expect(order.doctorName, isNull);
    expect(order.orderedAt, isNull);
    expect(order.details.map((d) => d.status), [DetailStatus.completed, DetailStatus.pending]);
    expect(order.details.first.results.map((r) => r.name), ['Hemoglobina', 'Hematocrito']);
    expect(order.details.first.results.first.valueNumeric, 14.2);
    expect(order.details.first.results.last.valueText, 'normal');
    expect(order.details.first.validatedResults, hasLength(2));
    expect(order.details.last.results, isEmpty);
  });

  test('remembers the orders opened by code, per patient', () async {
    final repo = _repo();
    await repo.findOrder(patientId: 'u1', code: _orderId);
    await repo.findOrder(patientId: 'u1', code: _orderId);

    expect(await repo.ordersOf('u1'), hasLength(1));
    expect(await repo.ordersOf('u2'), isEmpty);
  });

  test('refuses a code that is not a UUID without calling the API', () async {
    await expectLater(
      _repo().findOrder(patientId: 'u1', code: 'ORD-0501'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
    );
  });

  test('an order that is not the patient\'s surfaces the 403', () async {
    await expectLater(
      _repo(orderStatus: 403).findOrder(patientId: 'u1', code: _orderId),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.forbidden)),
    );
  });

  test('the lookup requires a code', () async {
    await expectLater(
      LookupLabOrder(_repo())(patientId: 'u1', code: '  '),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
    );
  });

  test('the lookup never exposes a result that is not validated', () async {
    final repo = _FixedRepo(
      LabOrder(
        id: 'o',
        patientId: 'u1',
        priority: OrderPriority.normal,
        status: OrderStatus.inProgress,
        details: [
          OrderDetail(
            id: 'd',
            testName: 'Prueba 1',
            status: DetailStatus.inProgress,
            results: const [
              AnalyteResult(name: 'visible', validated: true),
              AnalyteResult(name: 'draft'),
            ],
          ),
        ],
      ),
    );

    final order = await LookupLabOrder(repo)(patientId: 'u1', code: 'o');

    expect(order.details.single.results.map((r) => r.name), ['visible']);
  });
}

class _FixedRepo extends HttpLabResultsRepository {
  _FixedRepo(this._order) : super(ApiClient(client: MockClient((_) async => http.Response('', 500)), baseUrl: 'http://x'));

  final LabOrder _order;

  @override
  Future<LabOrder> findOrder({required String patientId, required String code}) async => _order;
}
