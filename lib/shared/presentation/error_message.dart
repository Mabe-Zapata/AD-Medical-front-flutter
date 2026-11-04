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
  ErrorKind.notFound: 'No encontramos lo que buscas.',
  ErrorKind.conflict: 'No se pudo completar la acción porque los datos cambiaron. Inténtalo de nuevo.',
  ErrorKind.validation: 'Revisa los datos ingresados e inténtalo de nuevo.',
  ErrorKind.rateLimited: 'Demasiados intentos. Espera un minuto e inténtalo de nuevo.',
  ErrorKind.network: 'No se pudo conectar con el servidor. Revisa la conexión e inténtalo de nuevo.',
  ErrorKind.unavailable: 'El servidor no está disponible en este momento. Inténtalo de nuevo en unos minutos.',
  ErrorKind.notPatient: 'Esta cuenta es del personal. Ingresa al sistema interno.',
  ErrorKind.unknown: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
};

/// Names of the fields the API can report, as a patient reads them.
const _fieldNames = <String, String>{
  'email': 'el correo',
  'password': 'la contraseña',
  'first_name': 'los nombres',
  'last_name': 'los apellidos',
  'phone': 'el teléfono',
  'motivo': 'el motivo',
};

/// Turns any thrown value into Spanish copy. [overrides] lets a screen say something more precise.
///
/// `AppError.message` is internal (English, for logs and tests) and is never shown. The only thing taken
/// from it is the list of fields the backend rejected, which is translated.
ErrorView describeError(Object error, {Map<ErrorKind, String> overrides = const {}}) {
  if (error is! AppError) return const ErrorView('Ocurrió un error inesperado. Inténtalo de nuevo.');
  final override = overrides[error.kind];
  final message = override ?? (error.kind == ErrorKind.validation ? _validationMessage(error) : _messages[error.kind]!);
  return ErrorView(message, supportCode: error.correlationId);
}

String _validationMessage(AppError error) {
  final match = RegExp(r'^Invalid fields: (.+)$').firstMatch(error.message);
  final names = <String>{
    for (final field in (match?.group(1) ?? '').split(',')) ?_fieldNames[field.trim()],
  }.toList();
  if (names.isEmpty) return _messages[ErrorKind.validation]!;
  final list = names.length == 1 ? names.single : '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  return 'Revisa $list e inténtalo de nuevo.';
}
