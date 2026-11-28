import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/account_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._auth, this._store, {this._now = DateTime.now});

  final AuthRepository _auth;
  final SessionStore _store;
  final DateTime Function() _now;

  Future<Session> call({required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      throw const AppError(ErrorKind.validation, 'email and password are required');
    }
    final issued = await _auth.login(email: normalized, password: password);
    final patient = await _auth.fetchProfile(token: issued.token, email: normalized);
    // A valid staff account is not a backend error, but it does not belong here:
    // nothing is stored and the token is discarded.
    if (!isPatientAccount(patient.roles)) {
      throw const AppError(ErrorKind.notPatient, 'this account does not belong to a patient');
    }
    final session = Session(
      token: issued.token,
      expiresAt: _now().add(issued.expiresIn),
      patient: patient,
    );
    _store.save(session);
    return session;
  }
}
