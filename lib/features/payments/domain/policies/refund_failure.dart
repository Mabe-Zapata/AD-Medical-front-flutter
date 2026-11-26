import 'package:medicalbooking_portal/core/domain/app_error.dart';

/// What the patient reads when a refund request fails. The backend sends a rule code as the problem detail;
/// it is only used to tell the cases apart and is never shown.
String refundFailureMessage(AppError error) {
  if (error.kind == ErrorKind.network) {
    return 'No pudimos conectar con el servidor. Verifica tu conexión e intenta nuevamente.';
  }
  final code = error.message;
  for (final (rule, text) in _rules) {
    if (code.contains(rule)) return text;
  }
  return switch (error.status) {
    401 => 'Tu sesión venció. Inicia sesión de nuevo para continuar.',
    404 => 'No encontramos el pago de esta cita. Si recargaste la página, comunícate con el laboratorio.',
    422 => 'No pudimos enviar la solicitud. Revisa el motivo e intenta nuevamente.',
    502 || 503 => 'El proveedor de pagos no respondió y el reembolso no se registró. Inténtalo más tarde.',
    _ => 'No pudimos solicitar el reembolso. Inténtalo más tarde o contacta al laboratorio.',
  };
}

/// Why the patient cannot ask for a refund of a cancelled appointment, as a sentence for the card.
String refundBlockMessage(String code) => refundFailureMessage(AppError(ErrorKind.conflict, code));

const _rules = <(String, String)>[
  ('PAGO_NO_CONFIRMADO', 'Este pago todavía no está confirmado, así que no hay nada que reembolsar.'),
  ('CITA_NO_CANCELADA', 'Cancela la cita antes de pedir el reembolso.'),
  ('CONSULTA_ATENDIDA', 'La consulta ya fue atendida, por eso no se puede reembolsar.'),
  ('CANCELACION_TARDIA', 'Las cancelaciones con menos de 48 horas de anticipación no tienen reembolso.'),
  ('REEMBOLSO_EXISTENTE', 'Ya hay un reembolso en curso para este pago.'),
  ('FUERA_DE_VENTANA', 'Ya pasó el plazo para pedir el reembolso de este pago.'),
  ('SIN_PAYMENT_INTENT', 'Este pago no se puede reembolsar desde el portal. Contacta al laboratorio.'),
  ('MOTIVO_INVALIDO', 'Elige un motivo válido para el reembolso.'),
];
