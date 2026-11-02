import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

abstract interface class LabResultsRepository {
  Future<List<LabOrder>> ordersOf(String patientId);
}
