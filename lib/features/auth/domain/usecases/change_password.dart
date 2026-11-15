import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/password_change_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

/// Replaces the signed-in patient's password after proving the current one.
class ChangePassword {
  const ChangePassword(this._auth);

  final AuthRepository _auth;

  Future<void> call({
    required String email,
    required String current,
    required String next,
    required String confirmation,
  }) async {
    final problems = passwordChangeProblems(current: current, next: next, confirmation: confirmation);
    if (problems.isNotEmpty) {
      throw AppError(ErrorKind.validation, 'password change rejected: ${problems.first.name}');
    }
    await _auth.changePassword(email: email, current: current, next: next);
  }
}
