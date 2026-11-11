/// Port: pays for an appointment.
abstract interface class PaymentRepository {
  /// Invoices the appointment (once) and opens a checkout for it.
  ///
  /// Returns the hosted payment page to send the patient to, or null when the payment was settled
  /// without leaving the app (demo mode).
  Future<Uri?> startCheckout({required String patientId, required String appointmentId});
}
