import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';

void main() {
  test('never shows the internal English message', () {
    for (final kind in ErrorKind.values) {
      final view = describeError(
        AppError(kind, 'email and password are required'),
      );

      expect(view.message, isNot(contains('required')), reason: '$kind');
      expect(view.message, isNot(contains('email and')), reason: '$kind');
      expect(view.message, isNotEmpty);
    }
  });

  test('a validation error without known fields says to review the data', () {
    final view = describeError(
      const AppError(ErrorKind.validation, 'something odd'),
    );

    expect(
      view.message,
      'Hay datos que no pudimos aceptar. Revísalos y vuelve a intentarlo.',
    );
  });

  test('translates the fields the backend rejected', () {
    expect(
      describeError(
        const AppError(ErrorKind.validation, 'Invalid fields: email'),
      ).message,
      'Revisa el correo e inténtalo de nuevo.',
    );
    expect(
      describeError(
        const AppError(
          ErrorKind.validation,
          'Invalid fields: email, password, first_name',
        ),
      ).message,
      'Revisa el correo, la contraseña y los nombres e inténtalo de nuevo.',
    );
  });

  test('ignores fields it does not know instead of leaking their names', () {
    final view = describeError(
      const AppError(ErrorKind.validation, 'Invalid fields: id, is_active'),
    );

    expect(view.message, isNot(contains('is_active')));
  });

  test('a screen can say something more precise', () {
    final view = describeError(
      const AppError(ErrorKind.conflict, 'x', correlationId: 'c-1'),
      overrides: {ErrorKind.conflict: 'Ya existe una cuenta con ese correo.'},
    );

    expect(view.message, 'Ya existe una cuenta con ese correo.');
  });

  test(
    'anything that is not an AppError becomes a generic Spanish message',
    () {
      expect(
        describeError(StateError('boom')).message,
        'Algo salió mal de nuestro lado. Inténtalo de nuevo.',
      );
    },
  );
}
