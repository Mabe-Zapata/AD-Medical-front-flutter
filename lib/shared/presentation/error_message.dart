import 'package:medicalbooking_portal/core/domain/app_error.dart';

class ErrorView {
  const ErrorView(this.message, {this.supportCode});

  final String message;

  /// Correlation id the backend returned, so support can find the request in the logs.
  final String? supportCode;
}

const _messages = <ErrorKind, String>{
  ErrorKind.invalidCredentials: 'Correo o contraseña incorrectos.',
  ErrorKind.unauthenticated: 'Tu sesión terminó. Inicia sesión de nuevo.',
  ErrorKind.forbidden: 'No tienes permiso para realizar esta acción.',
  ErrorKind.notFound: 'No se encontró el recurso solicitado.',
  ErrorKind.conflict: 'La operación entra en conflicto con el estado actual del recurso.',
  ErrorKind.validation: 'Los datos enviados no son válidos.',
  ErrorKind.rateLimited: 'Demasiados intentos. Espera un minuto e inténtalo de nuevo.',
  ErrorKind.network: 'No se pudo conectar con el servidor. Revisa la conexión e inténtalo de nuevo.',
  ErrorKind.unavailable: 'El servidor no está disponible en este momento. Inténtalo de nuevo en unos minutos.',
  ErrorKind.notPatient: 'Esta cuenta es del personal. Ingresa al sistema interno.',
  ErrorKind.unknown: 'Ocurrió un error inesperado.',
};

/// Turns any thrown value into Spanish copy. [overrides] lets a screen say something more precise.
ErrorView describeError(Object error, {Map<ErrorKind, String> overrides = const {}}) {
  if (error is! AppError) return const ErrorView('Ocurrió un error inesperado.');
  var message = overrides[error.kind] ?? _messages[error.kind]!;
  // The backend names the fields that failed (never their values), which helps fix the form.
  if (error.kind == ErrorKind.validation && !overrides.containsKey(ErrorKind.validation) && error.message.isNotEmpty) {
    message = '$message ${error.message}';
  }
  return ErrorView(message, supportCode: error.correlationId);
}
