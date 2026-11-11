import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

class StartCheckout {
  const StartCheckout(this._repository);

  final PaymentRepository _repository;

  /// Only an appointment that still waits for payment can be paid.
  Future<Uri?> call({required String patientId, required Appointment appointment}) =>
      _repository.startCheckout(patientId: patientId, appointmentId: appointment.id);
}
