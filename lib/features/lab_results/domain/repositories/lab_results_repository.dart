import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

/// Port to the laboratory API. Implementations throw `AppError` on failure.
abstract interface class LabResultsRepository {
  /// The patient's own orders, newest first, each with its results.
  Future<List<LabOrder>> ordersOf(String patientId);
}
