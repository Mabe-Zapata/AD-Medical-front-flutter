import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/restore_session.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_in.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_out.dart';

class _FakeAuth implements AuthRepository {
  _FakeAuth(this.roles, {this.failure});

  final List<String> roles;
  final AppError? failure;
  final loginCalls = <List<String>>[];
  var profileCalls = 0;

  @override
  Future<IssuedToken> login({required String email, required String password}) async {
    loginCalls.add([email, password]);
    if (failure != null) throw failure!;
    return const IssuedToken(token: 'jwt', expiresIn: Duration(minutes: 15));
  }

  @override
  Future<void> register(NewPatientAccount account) async {}

  @override
  Future<Patient> fetchProfile({required String token, required String email}) async {
    profileCalls++;
    return Patient(id: 'u1', email: email, roles: roles);
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);

  test('stores a session that expires with the token for a patient account', () async {
    final store = MemorySessionStore();
    final session = await SignIn(_FakeAuth(['PACIENTE']), store, now: () => now)(
      email: 'p@demo.test',
      password: 'secret',
    );

    expect(session.expiresAt, now.add(const Duration(minutes: 15)));
    expect(store.load(), same(session));
  });

  test('sends a trimmed, lower-case email to the API', () async {
    final auth = _FakeAuth(['PACIENTE']);
    await SignIn(auth, MemorySessionStore())(email: '  P@Demo.TEST ', password: 'secret');
    expect(auth.loginCalls, [
      ['p@demo.test', 'secret'],
    ]);
  });

  test('rejects a staff account and keeps nothing', () async {
    final store = MemorySessionStore();

    await expectLater(
      SignIn(_FakeAuth(['MEDICO']), store)(email: 'd@demo.test', password: 'x'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.notPatient)),
    );
    expect(store.load(), isNull);
  });

  test('propagates wrong credentials without asking for the profile', () async {
    final auth = _FakeAuth(['PACIENTE'], failure: const AppError(ErrorKind.invalidCredentials, 'nope'));

    await expectLater(
      SignIn(auth, MemorySessionStore())(email: 'a@b.test', password: 'bad'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.invalidCredentials)),
    );
    expect(auth.profileCalls, 0);
  });

  test('does not call the API for an empty email or password', () async {
    final auth = _FakeAuth(['PACIENTE']);
    final signIn = SignIn(auth, MemorySessionStore());

    await expectLater(signIn(email: ' ', password: 'x'), throwsA(isA<AppError>()));
    await expectLater(signIn(email: 'a@b.test', password: ''), throwsA(isA<AppError>()));
    expect(auth.loginCalls, isEmpty);
  });

  group('RestoreSession and SignOut', () {
    final live = Session(token: 't', expiresAt: now.add(const Duration(minutes: 1)), patient: const Patient(id: 'u', email: 'e'));

    test('restores a session that has not expired', () {
      final store = MemorySessionStore()..save(live);
      expect(RestoreSession(store, now: () => now)(), same(live));
    });

    test('drops an expired session from the store', () {
      final store = MemorySessionStore()..save(live);
      expect(RestoreSession(store, now: () => now.add(const Duration(minutes: 1)))(), isNull);
      expect(store.load(), isNull);
    });

    test('clears the store on sign out', () {
      final store = MemorySessionStore()..save(live);
      SignOut(store)();
      expect(store.load(), isNull);
    });
  });
}
