import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

class RequestRefund {
  const RequestRefund(this._repository);

  final PaymentRepository _repository;

  /// Only a cancelled appointment whose payment this app run knows can be refunded from here.
  bool canRequest(Appointment appointment) =>
      appointment.status == AppointmentStatus.cancelled && _repository.knowsPayment(appointment.id);

  Future<Refund> call({
    required String patientId,
    required Appointment appointment,
    required RefundReason reason,
    String? text,
  }) {
    if (!canRequest(appointment)) {
      throw const AppError(ErrorKind.conflict, 'only a cancelled, known payment can be refunded');
    }
    return _repository.requestRefund(patientId: patientId, appointmentId: appointment.id, reason: reason, text: text);
  }
}
