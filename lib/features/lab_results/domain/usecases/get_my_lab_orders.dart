import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/repositories/lab_results_repository.dart';

class GetMyLabOrders {
  const GetMyLabOrders(this._repository);

  final LabResultsRepository _repository;

  /// Permission rule: a patient only gets their own orders, and an analyte
  /// is exposed only once the laboratory has validated it. Newest first.
  Future<List<LabOrder>> call(String patientId) async {
    final orders = await _repository.ordersOf(patientId);
    return [
      for (final order in orders.where((o) => o.patientId == patientId)) _onlyValidated(order),
    ]..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
  }

  LabOrder _onlyValidated(LabOrder order) => LabOrder(
    id: order.id,
    patientId: order.patientId,
    doctorName: order.doctorName,
    orderedAt: order.orderedAt,
    priority: order.priority,
    status: order.status,
    notes: order.notes,
    details: [
      for (final detail in order.details)
        OrderDetail(
          id: detail.id,
          testName: detail.testName,
          status: detail.status,
          sampleTakenAt: detail.sampleTakenAt,
          resultAt: detail.resultAt,
          results: detail.validatedResults,
        ),
    ],
  );
}
