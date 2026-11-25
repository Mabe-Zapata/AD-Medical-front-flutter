import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';

/// Port: pays for an appointment.
abstract interface class PaymentRepository {
  /// Invoices the appointment (once) and opens a checkout for it. Says where the patient pays: a hosted
  /// page, or a form inside the portal.
  Future<CheckoutStart> startCheckout({required String patientId, required String appointmentId});

  /// True when this app run knows the payment of the appointment. The API has no listing of invoices or
  /// payments, so only a payment started in this run can be followed up or refunded.
  bool knowsPayment(String appointmentId);

  /// Where the latest payment attempt of the appointment stands. Needs [knowsPayment].
  Future<CheckoutStatus> checkoutStatus({required String patientId, required String appointmentId});

  /// Where the most recent payment attempt started in this run stands, or null when none was started. Used when the
  /// patient comes back from the provider: a return never proves the payment by itself.
  Future<CheckoutStatus?> latestAttempt({required String patientId});

  /// Asks for the whole payment back. Needs [knowsPayment]. A retry of the same request reuses its idempotency
  /// key, so it never creates a second refund.
  /// The state of the newest refund of the appointment's payment, read at Stripe through the backend:
  /// `PENDIENTE`, `PROCESADO` or `FALLIDO`. Null when the payment has no refund.
  Future<String?> refundStatus({required String patientId, required String appointmentId});

  Future<Refund> requestRefund({
    required String patientId,
    required String appointmentId,
    required RefundReason reason,
    String? text,
    String? paymentId,
  });
}
