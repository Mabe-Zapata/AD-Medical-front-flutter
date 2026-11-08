import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Token that the demo accepts as a valid email link: `#/verificar?token=demo`.
const demoVerificationToken = 'demo';

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._db);

  final DemoDatabase _db;

  /// Accounts created with [register]; they live as long as the page.
  final _registered = <String, ({String password, Patient patient})>{};

  @override
  Future<IssuedToken> login({required String email, required String password}) async {
    await _db.simulateLatency();
    final isDemoAccount = email == DemoDatabase.demoEmail && password == DemoDatabase.demoPassword;
    if (!isDemoAccount && _registered[email]?.password != password) {
      throw const AppError(ErrorKind.invalidCredentials, 'invalid credentials');
    }
    return const IssuedToken(token: 'demo-token', expiresIn: Duration(minutes: 15));
  }

  @override
  Future<void> register(NewPatientAccount account) async {
    await _db.simulateLatency();
    // Like the real API: the same answer whether or not the email already has an account.
    if (account.email == DemoDatabase.demoEmail || _registered.containsKey(account.email)) return;
    _registered[account.email] = (
      password: account.password,
      patient: Patient(
        id: 'patient-${_registered.length + 1}',
        email: account.email,
        firstName: account.firstName,
        lastName: account.lastName,
        roles: const ['PACIENTE'],
        permissions: const ['citas.reservar', 'citas.leer_propias', 'resultados.leer_propios'],
      ),
    );
  }

  /// The demo activates accounts at once; this only accepts the token the demo link would carry.
  @override
  Future<void> verifyEmail(String token) async {
    await _db.simulateLatency();
    if (token != demoVerificationToken) {
      throw const AppError(ErrorKind.validation, 'link invalid, already used or expired');
    }
  }

  @override
  Future<Patient> fetchProfile({required String token, required String email}) async =>
      _registered[email]?.patient ?? _db.patient;
}
