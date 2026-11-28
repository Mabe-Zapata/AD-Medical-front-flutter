import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

/// Creates a patient account. Signing in afterwards is the session's job.
class RegisterPatient {
  const RegisterPatient(this._auth);

  final AuthRepository _auth;

  /// Returns the normalized account that was sent, so the caller can sign in with it.
  Future<NewPatientAccount> call(NewPatientAccount account) async {
    final clean = account.normalized();
    final problems = registrationProblems(clean);
    if (problems.isNotEmpty) {
      throw AppError(ErrorKind.validation, problems.map((p) => p.name).join(', '));
    }
    await _auth.register(clean);
    return clean;
  }
}
