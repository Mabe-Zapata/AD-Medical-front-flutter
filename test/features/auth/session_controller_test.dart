import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// A backend that signs in `paciente@demo.test` and answers everything else with [other].
MockClient _backend({List<String> roles = const ['PACIENTE'], int other = 200}) => MockClient((request) async {
  if (request.url.path.endsWith('/auth/login')) {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    if (body['password'] != 'right') return _json({'detail': 'Invalid credentials'}, 401);
    return _json({'access_token': 'jwt', 'token_type': 'Bearer', 'expires_in': 900}, 200);
  }
  if (request.url.path.endsWith('/me')) {
    return _json({'id': 'u1', 'roles': roles, 'permissions': ['citas.reservar']}, 200);
  }
  return _json({'detail': 'x'}, other);
});

void main() {
  late DateTime clock;

  SessionController build(MockClient client, {MemorySessionStore? store}) => AppDependencies.api(
    apiBaseUrl: 'http://api.test/api/v1',
    client: client,
    store: store ?? MemorySessionStore(),
    now: () => clock,
  ).session;

  setUp(() => clock = DateTime.utc(2026, 11, 3, 12));

  test('signs a patient in through the API and exposes the profile', () async {
    final session = build(_backend());
    expect(session.isSignedIn, isFalse);

    await session.signIn('Paciente@Demo.test', 'right');

    expect(session.isSignedIn, isTrue);
    expect(session.patient!.id, 'u1');
    expect(session.patient!.email, 'paciente@demo.test');
    expect(session.patient!.displayName, 'paciente@demo.test');
    expect(session.patient!.can('citas.reservar'), isTrue);
    expect(session.token, 'jwt');
  });

  test('wrong credentials leave the session closed', () async {
    final session = build(_backend());
    await expectLater(
      session.signIn('paciente@demo.test', 'wrong'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.invalidCredentials)),
    );
    expect(session.isSignedIn, isFalse);
  });

  test('a staff account is rejected and nothing is stored', () async {
    final store = MemorySessionStore();
    final session = build(_backend(roles: ['MEDICO']), store: store);

    await expectLater(
      session.signIn('doctor@demo.test', 'right'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.notPatient)),
    );
    expect(session.isSignedIn, isFalse);
    expect(store.load(), isNull);
  });

  test('a stored session is restored after a reload, unless it expired', () async {
    final store = MemorySessionStore();
    await build(_backend(), store: store).signIn('paciente@demo.test', 'right');

    expect(build(_backend(), store: store).isSignedIn, isTrue);

    clock = clock.add(const Duration(minutes: 16));
    expect(build(_backend(), store: store).isSignedIn, isFalse);
    expect(store.load(), isNull);
  });

  test('the session ends as expired once the token lapses', () async {
    final session = build(_backend());
    await session.signIn('paciente@demo.test', 'right');

    clock = clock.add(const Duration(minutes: 15));

    expect(session.isSignedIn, isFalse);
    expect(session.endReason, EndReason.expired);
  });

  test('a manual sign out is not reported as an expiry', () async {
    final session = build(_backend());
    await session.signIn('paciente@demo.test', 'right');
    session.signOut();
    expect(session.endReason, EndReason.closed);
  });
}
