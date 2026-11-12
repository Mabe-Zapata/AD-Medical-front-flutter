import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/repositories/lab_results_repository.dart';

/// Talks to /api/v1/lab/orders. The listing carries no results, so each order is read with its results.
class HttpLabResultsRepository implements LabResultsRepository {
  HttpLabResultsRepository(this._api);

  /// How many of the newest orders are opened with their results.
  static const _newest = 20;

  final ApiClient _api;

  @override
  Future<List<LabOrder>> ordersOf(String patientId) async {
    final list = await _api.get(
      '/lab/orders',
      query: {'limit': '$_newest'},
    ) as Map<String, dynamic>;
    final items = [
      for (final item in list['items'] as List) item as Map<String, dynamic>,
    ];
    final orders = await Future.wait(
      items.map(
        (item) => _read(
          item['id'] as String,
          patientId,
          DateTime.tryParse('${item['fecha']}'),
        ),
      ),
    );
    // The listing is newest first and so is the result.
    return orders.whereType<LabOrder>().toList();
  }

  /// One order with its results, or null when it cannot be read: one bad order must not hide the others.
  Future<LabOrder?> _read(
    String id,
    String patientId,
    DateTime? orderedAt,
  ) async {
    try {
      final order = await _api.get('/lab/orders/$id') as Map<String, dynamic>;
      final results =
          await _api.get('/lab/orders/$id/results') as Map<String, dynamic>;
      return _order(order, results, patientId, orderedAt);
    } on AppError {
      return null;
    }
  }

  LabOrder _order(
    Map<String, dynamic> order,
    Map<String, dynamic> results,
    String patientId,
    DateTime? orderedAt,
  ) {
    final byDetail = <String, List<AnalyteResult>>{};
    for (final item in results['items'] as List) {
      final r = item as Map<String, dynamic>;
      byDetail
          .putIfAbsent(r['detalle_id'] as String, () => [])
          .add(
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
      priority: order['prioridad'] == 'URGENTE'
          ? OrderPriority.urgent
          : OrderPriority.normal,
      status: _orderStatus(order['estado'] as String),
      orderedAt: orderedAt,
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
