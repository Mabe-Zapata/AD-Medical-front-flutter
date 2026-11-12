import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';

/// Port: pays for an appointment.
abstract interface class PaymentRepository {
  /// Invoices the appointment (once) and opens a checkout for it. Says where the patient pays: a hosted
  /// page, or a form inside the portal.
  Future<CheckoutStart> startCheckout({required String patientId, required String appointmentId});
}
