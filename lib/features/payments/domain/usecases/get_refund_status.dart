import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

/// Asks the backend, which asks Stripe, where the refund of an appointment stands. Null when there is none.
class GetRefundStatus {
  const GetRefundStatus(this._repository);

  final PaymentRepository _repository;

  Future<String?> call({required String patientId, required Appointment appointment}) =>
      _repository.refundStatus(patientId: patientId, appointmentId: appointment.id);
}
