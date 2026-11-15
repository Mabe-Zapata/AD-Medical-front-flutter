/// pagos.estado of the latest checkout attempt of an invoice.
enum CheckoutState { pending, confirmed, rejected, cancelled }

/// GET /invoices/{id}/checkout-status: where the latest payment attempt stands. Only the backend's signed
/// webhook moves it to [CheckoutState.confirmed].
class CheckoutStatus {
  const CheckoutStatus({
    required this.paymentId,
    required this.state,
    required this.retriesDone,
    required this.retriesMax,
    required this.retriesExhausted,
    this.nextRetryAt,
    this.lastErrorCode,
  });

  final String paymentId;
  final CheckoutState state;
  final int retriesDone;
  final int retriesMax;
  final bool retriesExhausted;
  final DateTime? nextRetryAt;

  /// Technical (for logs); never shown to the patient.
  final String? lastErrorCode;
}
