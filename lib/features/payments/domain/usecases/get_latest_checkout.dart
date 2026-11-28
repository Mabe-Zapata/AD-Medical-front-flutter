import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

/// Where the most recent payment attempt of this run stands, or null when none was started. Used when the
/// patient comes back from the provider: the return alone never proves the payment.
class GetLatestCheckout {
  const GetLatestCheckout(this._repository);

  final PaymentRepository _repository;

  Future<CheckoutStatus?> call({required String patientId}) => _repository.latestAttempt(patientId: patientId);
}
