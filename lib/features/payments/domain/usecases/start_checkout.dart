import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

class StartCheckout {
  const StartCheckout(this._repository);

  final PaymentRepository _repository;

  Future<CheckoutStart> call({required String patientId, required Appointment appointment}) =>
      _repository.startCheckout(patientId: patientId, appointmentId: appointment.id);
}
