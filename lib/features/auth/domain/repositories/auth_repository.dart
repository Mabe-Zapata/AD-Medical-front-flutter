import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';

abstract interface class AuthRepository {
  /// Returns the patient when the credentials are valid, otherwise null.
  Future<Patient?> signIn({required String email, required String password});

  Future<void> signOut();
}
