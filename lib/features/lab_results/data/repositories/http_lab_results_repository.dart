import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/domain/ids.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/repositories/lab_results_repository.dart';

/// Talks to /api/v1/lab/orders. The API cannot list a patient's orders, so the ones opened by
/// code in this app run are remembered here (keyed by patient).
class HttpLabResultsRepository implements LabResultsRepository {
  HttpLabResultsRepository(this._api);

  final ApiClient _api;
  final List<LabOrder> _known = [];

  @override
  Future<List<LabOrder>> ordersOf(String patientId) async =>
      _known.where((o) => o.patientId == patientId).toList();

  @override
  Future<LabOrder> findOrder({required String patientId, required String code}) async {
    if (!isUuid(code)) {
      throw const AppError(ErrorKind.validation, 'the order code is not valid');
    }
    final id = code.trim().toLowerCase();
    final order = await _api.get('/lab/orders/$id') as Map<String, dynamic>;
    final results = await _api.get('/lab/orders/$id/results') as Map<String, dynamic>;
    final mapped = _order(order, results, patientId);
    _known
      ..removeWhere((o) => o.id == mapped.id && o.patientId == patientId)
      ..insert(0, mapped);
    return mapped;
  }

  LabOrder _order(Map<String, dynamic> order, Map<String, dynamic> results, String patientId) {
    final byDetail = <String, List<AnalyteResult>>{};
    for (final item in results['items'] as List) {
      final r = item as Map<String, dynamic>;
      byDetail.putIfAbsent(r['detalle_id'] as String, () => []).add(
        AnalyteResult(
          name: r['nombre_analito'] as String,
          valueNumeric: (r['valor_numerico'] as num?)?.toDouble(),
          valueText: r['valor_texto'] as String?,
          unit: r['unidad'] as String?,
          validated: true,
        ),
      );
    }
    final tests = order['pruebas'] as List;
    return LabOrder(
      id: order['id'] as String,
      // The app identifies the patient by the user id, not by the API's patient id.
      patientId: patientId,
      priority: order['prioridad'] == 'URGENTE' ? OrderPriority.urgent : OrderPriority.normal,
      status: _orderStatus(order['estado'] as String),
      notes: order['observaciones'] as String?,
      details: [
        for (var i = 0; i < tests.length; i++)
          OrderDetail(
            id: (tests[i] as Map)['detalle_id'] as String,
            // The API sends the test type id, not its name, and has no catalog to resolve it.
            testName: 'Prueba ${i + 1}',
            status: _detailStatus((tests[i] as Map)['estado'] as String),
            results: byDetail[(tests[i] as Map)['detalle_id']] ?? const [],
          ),
      ],
    );
  }

  OrderStatus _orderStatus(String code) => switch (code) {
    'SOLICITADA' => OrderStatus.requested,
    'EN_PROCESO' => OrderStatus.inProgress,
    'COMPLETADA' => OrderStatus.completed,
    'CANCELADA' => OrderStatus.cancelled,
    _ => throw AppError(ErrorKind.unknown, 'unknown order status $code'),
  };

  DetailStatus _detailStatus(String code) => switch (code) {
    'PENDIENTE' => DetailStatus.pending,
    'EN_PROCESO' => DetailStatus.inProgress,
    'COMPLETADO' => DetailStatus.completed,
    'CANCELADO' => DetailStatus.cancelled,
    _ => throw AppError(ErrorKind.unknown, 'unknown test status $code'),
  };
}
