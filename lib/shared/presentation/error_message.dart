import 'package:medicalbooking_portal/core/domain/app_error.dart';

/// Something to tell the person, in plain Spanish. It never carries technical codes: the person cannot do
/// anything with them, so they stay in the logs.
class ErrorView {
  const ErrorView(this.message);

  final String message;
}

const _messages = <ErrorKind, String>{
  ErrorKind.invalidCredentials: 'Ese correo y esa contraseña no coinciden. Revísalos e inténtalo otra vez.',
  ErrorKind.unauthenticated:
      'Tu sesión se cerró. Inicia sesión de nuevo para continuar.',
  ErrorKind.forbidden: 'Tu cuenta no tiene acceso a esta sección.',
  ErrorKind.notFound: 'No encontramos lo que buscas. Puede que ya no exista.',
  ErrorKind.conflict: 'Alguien actualizó esto al mismo tiempo que tú. Vuelve a cargar e inténtalo de nuevo.',
  ErrorKind.validation:
      'Hay datos que no pudimos aceptar. Revísalos y vuelve a intentarlo.',
  ErrorKind.rateLimited:
      'Hiciste varios intentos seguidos. Espera un minuto y vuelve a probar.',
  ErrorKind.network:
      'No pudimos conectarnos. Revisa tu internet y vuelve a intentarlo.',
  ErrorKind.unavailable: 'El servicio está tardando más de lo normal. Inténtalo de nuevo en unos minutos.',
  ErrorKind.notPatient:
      'Esta cuenta es del personal. Ingresa por el sistema interno.',
  ErrorKind.unknown: 'Algo salió mal de nuestro lado. Inténtalo de nuevo; si sigue pasando, contacta al laboratorio.',
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
ErrorView describeError(
  Object error, {
  Map<ErrorKind, String> overrides = const {},
}) {
  if (error is! AppError) {
    return const ErrorView(
      'Algo salió mal de nuestro lado. Inténtalo de nuevo.',
    );
  }
  final override = overrides[error.kind];
  final message =
      override ??
      (error.kind == ErrorKind.validation
          ? _validationMessage(error)
          : _messages[error.kind]!);
  return ErrorView(message);
}

String _validationMessage(AppError error) {
  final match = RegExp(r'^Invalid fields: (.+)$').firstMatch(error.message);
  final names = <String>{
    for (final field in (match?.group(1) ?? '').split(','))
      ?_fieldNames[field.trim()],
  }.toList();
  if (names.isEmpty) return _messages[ErrorKind.validation]!;
  final list = names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  return 'Revisa $list e inténtalo de nuevo.';
}
