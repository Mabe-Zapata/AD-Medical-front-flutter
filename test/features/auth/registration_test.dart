import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/register_patient.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

NewPatientAccount _account({String email = 'ana@demo.test', String password = 'una-clave-larga-1'}) =>
    NewPatientAccount(firstName: 'Ana', lastName: 'Pérez', email: email, phone: '+593991234567', password: password);

void main() {
  group('registration policy', () {
    test('accepts a complete account', () {
      expect(registrationProblems(_account()), isEmpty);
    });

    test('reports every field that is wrong', () {
      const account = NewPatientAccount(firstName: '', lastName: ' ', email: 'no-es-correo', phone: '123', password: 'corta');

      expect(registrationProblems(account.normalized()), RegistrationProblem.values);
    });

    test('the password minimum is the one the backend enforces', () {
      expect(minPasswordLength, 12);
      expect(registrationProblems(_account(password: '12345678901')), [RegistrationProblem.passwordLength]);
      expect(registrationProblems(_account(password: '123456789012')), isEmpty);
    });

    test('measures the strength from 0 to 4', () {
      expect(passwordStrength(''), 0);
      expect(passwordStrength('abc'), 0);
      expect(passwordStrength('abcdefghijkl'), 1);
      expect(passwordStrength('Abcdefghijk1'), 3);
      expect(passwordStrength('Abcdefghijk1!'), 4);
    });
  });

  group('RegisterPatient', () {
    test('normalizes the account before sending it', () async {
      final repository = DemoAuthRepository(DemoDatabase(latency: Duration.zero));
      final sent = await RegisterPatient(repository)(
        const NewPatientAccount(
          firstName: ' Ana ',
          lastName: 'Pérez ',
          email: ' ANA@Demo.test ',
          phone: '+593 99-123 4567',
          password: 'una-clave-larga-1',
        ),
      );

      expect(sent.email, 'ana@demo.test');
      expect(sent.firstName, 'Ana');
      expect(sent.phone, '+593991234567');
    });

    test('refuses an invalid account without calling the repository', () async {
      final repository = DemoAuthRepository(DemoDatabase(latency: Duration.zero));

      await expectLater(
        RegisterPatient(repository)(_account(password: 'corta')),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
      );
      await expectLater(
        repository.login(email: 'ana@demo.test', password: 'corta'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.invalidCredentials)),
      );
    });

    test('the new account can sign in and a repeated email is a conflict', () async {
      final repository = DemoAuthRepository(DemoDatabase(latency: Duration.zero));
      await RegisterPatient(repository)(_account());

      final token = await repository.login(email: 'ana@demo.test', password: 'una-clave-larga-1');
      final patient = await repository.fetchProfile(token: token.token, email: 'ana@demo.test');

      expect(patient.roles, ['PACIENTE']);
      expect(patient.displayName, 'Ana Pérez');
      await expectLater(
        RegisterPatient(repository)(_account()),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.conflict)),
      );
    });
  });
}
