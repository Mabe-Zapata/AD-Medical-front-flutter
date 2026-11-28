import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

/// "Verificar pago": asks the backend to settle the payment against the provider, not just to read it.
class ReconcileCheckout {
  const ReconcileCheckout(this._repository);

  final PaymentRepository _repository;

  Future<CheckoutStatus> call({required String patientId, required Appointment appointment}) =>
      _repository.reconcileCheckout(patientId: patientId, appointmentId: appointment.id);
}
