import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/domain/personal_data.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/http_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/register_patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/verify_email.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

const _longEnough = 'una-clave-larga-1';

final _today = DateTime(2026, 11, 14);

NewPatientAccount _with({String? documentType = 'CEDULA', String documentNumber = '1712345678', String? phone}) =>
    NewPatientAccount(
      firstName: 'Ana',
      lastName: 'Pérez',
      email: 'ana@demo.test',
      password: _longEnough,
      documentType: documentType,
      documentNumber: documentNumber,
      phone: phone,
      sex: BiologicalSex.female,
      birthDate: DateTime(1992, 5, 14),
    );

NewPatientAccount _account({
  String email = 'ana@demo.test',
  String secret = _longEnough,
  BiologicalSex? sex = BiologicalSex.female,
  DateTime? birthDate,
}) => NewPatientAccount(
  firstName: 'Ana',
  lastName: 'Pérez',
  email: email,
  password: secret,
  documentType: 'CEDULA',
  documentNumber: '1712345678',
  sex: sex,
  birthDate: birthDate ?? DateTime(1992, 5, 14),
);

DemoAuthRepository _repository() => DemoAuthRepository(DemoDatabase(latency: Duration.zero));

void main() {
  group('registration policy', () {
    test('accepts a complete account', () {
      expect(registrationProblems(_account(), now: _today), isEmpty);
    });

    test('asks for sex and birth date', () {
      expect(registrationProblems(_account(sex: null), now: _today), [RegistrationProblem.sex]);
      const noDate = NewPatientAccount(firstName: 'Ana', lastName: 'Pérez', email: 'ana@demo.test', password: _longEnough, documentType: 'CEDULA', documentNumber: '1712345678', sex: BiologicalSex.female);
      expect(registrationProblems(noDate, now: _today), [RegistrationProblem.birthDate]);
    });

    test('refuses a birth date in the future or more than 120 years ago', () {
      expect(registrationProblems(_account(birthDate: DateTime(2026, 11, 15)), now: _today), [RegistrationProblem.birthDate]);
      expect(registrationProblems(_account(birthDate: DateTime(1906, 11, 13)), now: _today), [RegistrationProblem.birthDate]);
      expect(registrationProblems(_account(birthDate: DateTime(2026, 11, 14)), now: _today), isEmpty);
    });

    test('reports every field that is wrong', () {
      const account = NewPatientAccount(firstName: '', lastName: ' ', email: 'no-es-correo', password: 'corta', documentType: null, documentNumber: '');

      expect(registrationProblems(account.normalized()), [
        RegistrationProblem.firstName,
        RegistrationProblem.lastName,
        RegistrationProblem.email,
        RegistrationProblem.document,
        RegistrationProblem.sex,
        RegistrationProblem.birthDate,
        RegistrationProblem.passwordLength,
      ]);
    });

    test('the identity document is required: a cédula has 10 digits, a passport 6 to 20 characters', () {
      expect(registrationProblems(_account(), now: _today), isEmpty);
      expect(registrationProblems(_with(documentType: 'CEDULA', documentNumber: '171234567'), now: _today), [RegistrationProblem.document]);
      expect(registrationProblems(_with(documentType: 'CEDULA', documentNumber: '17123456AB'), now: _today), [RegistrationProblem.document]);
      expect(registrationProblems(_with(documentType: 'PASAPORTE', documentNumber: 'AB12'), now: _today), [RegistrationProblem.document]);
      expect(registrationProblems(_with(documentType: null, documentNumber: '1712345678'), now: _today), [RegistrationProblem.document]);
      expect(registrationProblems(_with(documentType: 'PASAPORTE', documentNumber: 'AB123456'), now: _today), isEmpty);
    });

    test('the phone is optional, and when given it has 7 to 15 digits', () {
      expect(registrationProblems(_with(phone: null), now: _today), isEmpty);
      expect(registrationProblems(_with(phone: '+593 99-123 4567'), now: _today), isEmpty);
      expect(registrationProblems(_with(phone: '12'), now: _today), [RegistrationProblem.phone]);
    });

    test('the password minimum is the one the backend enforces', () {
      expect(minPasswordLength, 12);
      expect(registrationProblems(_account(secret: '12345678901'), now: _today), [RegistrationProblem.passwordLength]);
      expect(registrationProblems(_account(secret: '123456789012'), now: _today), isEmpty);
    });

    test('measures the strength from 0 to 4', () {
      expect(passwordStrength(''), 0);
      expect(passwordStrength('abc'), 0);
      expect(passwordStrength('abcdefghijkl'), 1);
      expect(passwordStrength('Abcdefghijk1'), 3);
      expect(passwordStrength('Abcdefghijk1!'), 4);
    });
  });

  group('HttpAuthRepository.register', () {
    Future<Map<String, dynamic>> sent(NewPatientAccount account) async {
      http.Request? captured;
      final api = ApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response('', 202);
        }),
        baseUrl: 'http://api.test/api/v1',
      );
      await HttpAuthRepository(api).register(account);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/auth/register');
      return jsonDecode(captured!.body) as Map<String, dynamic>;
    }

    test('sends sexo as M or F and fecha_nacimiento as a plain date', () async {
      final body = await sent(_account(sex: BiologicalSex.male, birthDate: DateTime(1990, 1, 2)));
      expect(body['sexo'], 'M');
      expect(body['fecha_nacimiento'], '1990-01-02');
      expect(body.keys.toSet(), {'email', 'password', 'first_name', 'last_name', 'tipo_documento', 'numero_documento', 'sexo', 'fecha_nacimiento'});
    });

    test('an account without phone or demographics sends the document and the name fields', () async {
      const bare = NewPatientAccount(firstName: 'Ana', lastName: 'Pérez', email: 'ana@demo.test', password: _longEnough, documentType: 'CEDULA', documentNumber: '1712345678');
      expect((await sent(bare)).keys.toSet(), {'email', 'password', 'first_name', 'last_name', 'tipo_documento', 'numero_documento'});
    });

    test('a phone is sent only when it is given', () async {
      final body = await sent(NewPatientAccount(firstName: 'Ana', lastName: 'Pérez', email: 'ana@demo.test', password: _longEnough, documentType: 'PASAPORTE', documentNumber: 'ab123456', phone: '+593 99 123 4567').normalized());
      expect(body['telefono'], '+593991234567');
      expect(body['numero_documento'], 'AB123456');
    });
  });

  group('RegisterPatient', () {
    test('normalizes the account before sending it', () async {
      final sent = await RegisterPatient(_repository())(
        NewPatientAccount(
          firstName: ' Ana ',
          lastName: 'Pérez ',
          email: ' ANA@Demo.test ',
          password: _longEnough,
          documentType: 'CEDULA',
          documentNumber: ' 1712345678 ',
          sex: BiologicalSex.male,
          birthDate: DateTime(1990, 1, 2),
        ),
      );

      expect(sent.email, 'ana@demo.test');
      expect(sent.firstName, 'Ana');
    });

    test('refuses an invalid account without calling the repository', () async {
      final repository = _repository();

      await expectLater(
        RegisterPatient(repository)(_account(secret: 'corta')),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
      );
      await expectLater(
        repository.login(email: 'ana@demo.test', password: 'corta'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.invalidCredentials)),
      );
    });

    test('the new account can sign in, and a repeated email gets the same answer', () async {
      final repository = _repository();
      await RegisterPatient(repository)(_account());

      final token = await repository.login(email: 'ana@demo.test', password: _longEnough);
      final patient = await repository.fetchProfile(token: token.token, email: 'ana@demo.test');

      expect(patient.roles, ['PACIENTE']);
      expect(patient.displayName, 'Ana Pérez');
      // The real API answers 202 whether or not the email exists, so the demo must not reveal it either.
      await RegisterPatient(repository)(_account());
    });
  });

  group('VerifyEmail', () {
    test('activates with the token of the link', () async {
      await VerifyEmail(_repository())(' $demoVerificationToken ');
    });

    test('a missing or blank token is refused before any call', () async {
      for (final token in [null, '', '   ']) {
        await expectLater(
          VerifyEmail(_repository())(token),
          throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
        );
      }
    });

    test('an invalid, used or expired link is a validation error', () async {
      await expectLater(
        VerifyEmail(_repository())('otro-token'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
      );
    });
  });
}
