import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

class RequestRefund {
  const RequestRefund(this._repository);

  final PaymentRepository _repository;

  /// Only a cancelled appointment whose payment this app run knows can be refunded from here. The backend's advice
  /// (notice, window and request limit) hides the button when it says the refund is not allowed; when it says
  /// nothing (not yet listed), the request itself is checked by the backend.
  bool canRequest(Appointment appointment) =>
      appointment.status == AppointmentStatus.cancelled &&
      appointment.refundEligible != false &&
      (appointment.paymentId != null || _repository.knowsPayment(appointment.id)) &&
      appointment.refundState != 'PENDIENTE' &&
      appointment.refundState != 'PROCESADO';

  Future<Refund> call({
    required String patientId,
    required Appointment appointment,
    required RefundReason reason,
    String? text,
  }) {
    if (!canRequest(appointment)) {
      throw const AppError(ErrorKind.conflict, 'only a cancelled, known payment can be refunded');
    }
    return _repository.requestRefund(
      patientId: patientId,
      appointmentId: appointment.id,
      reason: reason,
      text: text,
      paymentId: appointment.paymentId,
    );
  }
}
