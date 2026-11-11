import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/repositories/lab_results_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoLabResultsRepository implements LabResultsRepository {
  const DemoLabResultsRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<List<LabOrder>> ordersOf(String patientId) async {
    await _db.simulateLatency();
    return _db.orders.where((o) => o.patientId == patientId).toList();
  }
}
