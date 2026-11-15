import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

class GetCheckoutStatus {
  const GetCheckoutStatus(this._repository);

  final PaymentRepository _repository;

  /// True when this app run can follow up the payment of [appointment].
  bool canCheck(Appointment appointment) => _repository.knowsPayment(appointment.id);

  Future<CheckoutStatus> call({required String patientId, required Appointment appointment}) =>
      _repository.checkoutStatus(patientId: patientId, appointmentId: appointment.id);
}
