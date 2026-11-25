import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';

class IssuedToken {
  const IssuedToken({required this.token, required this.expiresIn});

  final String token;
  final Duration expiresIn;
}

/// Port to the identity API. Implementations throw `AppError` on failure.
abstract interface class AuthRepository {
  Future<IssuedToken> login({required String email, required String password});

  /// Public sign-up: always creates a patient. The account stays inactive until the person opens the link
  /// sent by email, and the server answers the same whether or not the email already had an account.
  Future<void> register(NewPatientAccount account);

  /// Activates the account behind the single-use token of the email link. Throws `AppError.validation`
  /// when the link is invalid, already used or expired.
  Future<void> verifyEmail(String token);

  /// Changes the password of the signed-in account after proving the current one. Throws `AppError.forbidden`
  /// when the current password is wrong; the session stays alive (only a 401 signs the patient out).
  Future<void> changePassword({required String email, required String current, required String next});

  /// Asks for a reset link. The answer is the same whether or not the email has an account.
  Future<void> requestPasswordReset(String email);

  /// Why a reset link cannot be used (`USED`, `EXPIRED`, `INVALID`), or `VALID` when it still can.
  Future<String> passwordResetStatus(String token);

  /// Sets the new password behind a single-use link. Throws `AppError` when the link is not usable.
  Future<void> confirmPasswordReset({required String token, required String password});

  /// Takes the token explicitly: the session does not exist yet while signing in.
  Future<Patient> fetchProfile({required String token, required String email});
}

/// Port to wherever the session survives a page reload.
abstract interface class SessionStore {
  Session? load();
  void save(Session session);
  void clear();
}
