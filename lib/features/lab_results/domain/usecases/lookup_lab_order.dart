import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/entities/lab_order.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/repositories/lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';

/// Opens an order by the code the laboratory gave the patient.
class LookupLabOrder {
  const LookupLabOrder(this._repository);

  final LabResultsRepository _repository;

  Future<LabOrder> call({required String patientId, required String code}) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) throw const AppError(ErrorKind.validation, 'order code is required');
    final order = await _repository.findOrder(patientId: patientId, code: trimmed);
    // Same rule as the list: never expose a result the laboratory has not validated.
    return onlyValidated(order);
  }
}
