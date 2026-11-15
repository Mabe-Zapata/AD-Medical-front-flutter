import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/http_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/password_change_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/change_password.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

// Built from repeated characters so no literal password sits in the source.
final _wrong = 'w' * 12;
final _next = 'n' * 12;

DemoAuthRepository _demo() => DemoAuthRepository(DemoDatabase(latency: Duration.zero));

void main() {
  group('passwordChangeProblems', () {
    test('a valid change has no problems', () {
      expect(passwordChangeProblems(current: _wrong, next: _next, confirmation: _next), isEmpty);
    });

    test('the new password needs the minimum length', () {
      expect(
        passwordChangeProblems(current: _wrong, next: 'corta', confirmation: 'corta'),
        {PasswordChangeProblem.newTooShort},
      );
    });

    test('the new password must differ from the current one', () {
      expect(
        passwordChangeProblems(current: _wrong, next: _wrong, confirmation: _wrong),
        {PasswordChangeProblem.newSameAsCurrent},
      );
    });

    test('the confirmation must match and the current password is required', () {
      expect(
        passwordChangeProblems(current: '', next: _next, confirmation: 'otra'),
        {PasswordChangeProblem.currentMissing, PasswordChangeProblem.confirmationMismatch},
      );
    });
  });

  group('ChangePassword use case', () {
    test('an invalid change never reaches the repository', () async {
      final repo = _demo();
      expect(
        ChangePassword(repo)(email: DemoDatabase.demoEmail, current: DemoDatabase.demoPassword, next: 'corta', confirmation: 'corta'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.validation)),
      );
    });
  });

  group('DemoAuthRepository.changePassword', () {
    test('a wrong current password is forbidden and the old password still works', () async {
      final repo = _demo();
      await expectLater(
        repo.changePassword(email: DemoDatabase.demoEmail, current: _wrong, next: _next),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.forbidden)),
      );
      await repo.login(email: DemoDatabase.demoEmail, password: DemoDatabase.demoPassword);
    });

    test('the new password works at the next sign-in and the old one stops working', () async {
      final repo = _demo();
      await repo.changePassword(email: DemoDatabase.demoEmail, current: DemoDatabase.demoPassword, next: _next);

      await repo.login(email: DemoDatabase.demoEmail, password: _next);
      await expectLater(
        repo.login(email: DemoDatabase.demoEmail, password: DemoDatabase.demoPassword),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.invalidCredentials)),
      );
    });
  });

  group('HttpAuthRepository.changePassword', () {
    test('posts both passwords to /me/password with the bearer session', () async {
      http.Request? captured;
      final api = ApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response('', 204);
        }),
        baseUrl: 'http://api.test/api/v1',
      );
      await HttpAuthRepository(api).changePassword(email: 'p@demo.test', current: _wrong, next: _next);

      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/me/password');
      expect(jsonDecode(captured!.body), {'current_password': _wrong, 'new_password': _next});
    });

    test('a 403 from the API is forbidden, which keeps the session', () async {
      final api = ApiClient(
        client: MockClient((_) async => http.Response('{"detail":"x"}', 403, headers: {'content-type': 'application/problem+json'})),
        baseUrl: 'http://api.test/api/v1',
      );
      await expectLater(
        HttpAuthRepository(api).changePassword(email: 'p@demo.test', current: _wrong, next: _next),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.forbidden)),
      );
    });
  });
}
