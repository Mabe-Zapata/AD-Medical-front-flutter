/// Closed catalog of reasons the backend accepts (`motivo_codigo`).
enum RefundReason {
  patientCancellation('CANCELACION_PACIENTE'),
  doctorCancellation('CANCELACION_MEDICO'),
  chargeError('ERROR_DE_COBRO');

  const RefundReason(this.code);

  final String code;
}

/// reembolsos.estado. It only becomes processed when the provider's webhook says so, so a freshly requested
/// refund is [pending], never "refunded".
enum RefundState { pending, failed }

/// POST /payments/{id}/refunds. The amount comes from the server, never from the client.
class Refund {
  const Refund({
    required this.id,
    required this.paymentId,
    required this.state,
    required this.amount,
    required this.reason,
    required this.requestedAt,
  });

  final String id;
  final String paymentId;
  final RefundState state;

  /// Decimal as the server sends it (`"45.00"`).
  final String amount;
  final String reason;
  final DateTime requestedAt;
}
