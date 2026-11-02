import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/lab_results/data/repositories/demo_lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

void main() {
  late DemoDatabase db;
  late GetMyLabOrders getOrders;

  setUp(() {
    db = DemoDatabase(latency: Duration.zero);
    getOrders = GetMyLabOrders(DemoLabResultsRepository(db));
  });

  test('a patient only gets their own orders, newest first', () async {
    final orders = await getOrders(db.patient.id);
    expect(orders.map((o) => o.id), ['ORD-0502', 'ORD-0501']);
    expect(await getOrders('someone-else'), isEmpty);
  });

  test('only validated results are visible', () async {
    db.orders.add(
      LabOrder(
        id: 'ORD-X',
        patientId: db.patient.id,
        doctorName: 'Dr. Test',
        orderedAt: DateTime.now().toUtc(),
        priority: OrderPriority.normal,
        status: OrderStatus.inProgress,
        details: [
          OrderDetail(
            id: 'd',
            testName: 'Test',
            status: DetailStatus.completed,
            results: [
              AnalyteResult(name: 'Validated', valueNumeric: 1, validatedAt: DateTime.now().toUtc()),
              const AnalyteResult(name: 'Draft', valueNumeric: 2),
            ],
          ),
        ],
      ),
    );

    final order = (await getOrders(db.patient.id)).firstWhere((o) => o.id == 'ORD-X');

    expect(order.details.single.results.map((r) => r.name), ['Validated']);
  });

  test('an order in progress has nothing to show, a finished one does', () async {
    final orders = await getOrders(db.patient.id);
    expect(orders.firstWhere((o) => o.status == OrderStatus.inProgress).hasValidatedResults, isFalse);
    expect(orders.firstWhere((o) => o.status == OrderStatus.completed).hasValidatedResults, isTrue);
  });
}
