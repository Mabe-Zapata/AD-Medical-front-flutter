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

  /// Takes the token explicitly: the session does not exist yet while signing in.
  Future<Patient> fetchProfile({required String token, required String email});
}

/// Port to wherever the session survives a page reload.
abstract interface class SessionStore {
  Session? load();
  void save(Session session);
  void clear();
}
