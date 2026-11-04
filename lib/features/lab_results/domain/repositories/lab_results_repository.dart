import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';

/// Port to the laboratory API. Implementations throw `AppError` on failure.
abstract interface class LabResultsRepository {
  /// Orders the patient can see. The real API has no listing, so this only knows the orders
  /// looked up by code since the app started.
  Future<List<LabOrder>> ordersOf(String patientId);

  /// Reads one order and its results by the code the laboratory gave the patient.
  /// Throws `AppError` (forbidden or not found) when it is not the patient's.
  Future<LabOrder> findOrder({required String patientId, required String code});
}
