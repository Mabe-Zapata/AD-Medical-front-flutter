import 'package:medicalbooking_portal/core/domain/app_error.dart';

/// What the patient reads when a payment fails. The backend's text is English and technical; it is only
/// used to tell the cases apart. The order matters: the first match wins (3D Secure arrives as a decline too).
String paymentFailureMessage(AppError error) {
  if (error.kind == ErrorKind.network) {
    return 'No pudimos conectar con el servidor. Verifica tu conexión e intenta nuevamente.';
  }
  switch (error.status) {
    case 400:
      return _badRequest(error.message);
    case 401:
      return 'Tu sesión venció. Inicia sesión de nuevo para pagar.';
    case 403:
      return 'No tienes permiso para realizar este pago.';
    case 409:
      return 'No se pudo completar el pago: la cita ya no está disponible para pagar.';
    default:
      return 'No pudimos procesar el pago por un problema del servidor. Inténtalo más tarde.';
  }
}

/// True when the problem is the card, so "Usar otra tarjeta" helps: a decline, 3D Secure, or no saved card.
bool paymentFailureIsTheCard(AppError error) =>
    error.status == 400 && _badRequest(error.message) != _generic;

const _generic = 'No pudimos procesar el pago. Revisa los datos e intenta nuevamente.';

const _declineReasons = <(String, String)>[
  ('insufficient funds', 'la tarjeta no tiene fondos suficientes'),
  ('expired', 'la tarjeta está vencida'),
  ('security code|cvc|cvv', 'el código de seguridad es incorrecto'),
  ('was declined|do not honor|generic', 'el banco rechazó la tarjeta'),
];

String _badRequest(String message) {
  final text = message.toLowerCase();
  if (text.contains('3d secure')) {
    return 'Tu banco pide autenticación adicional (3D Secure), que aún no está disponible. Prueba con otra tarjeta.';
  }
  if (text.startsWith('payment declined')) {
    for (final (pattern, reason) in _declineReasons) {
      if (RegExp(pattern).hasMatch(text)) return 'Tu pago fue rechazado: $reason. Prueba con otra tarjeta.';
    }
    return 'Tu pago fue rechazado. Prueba con otra tarjeta.';
  }
  if (text.contains('no tienes una tarjeta guardada')) {
    return 'No tienes una tarjeta guardada. Paga con una tarjeta nueva.';
  }
  return _generic;
}
