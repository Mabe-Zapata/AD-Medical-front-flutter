import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

/// Password reset from the emailed link: asks for a link, reads the state of a link, and sets the new password.
class PasswordReset {
  const PasswordReset(this._auth);

  final AuthRepository _auth;

  Future<void> request(String email) async {
    final clean = email.trim();
    if (clean.isEmpty) throw const AppError(ErrorKind.validation, 'the email is empty');
    await _auth.requestPasswordReset(clean);
  }

  /// `VALID` when the link can still be used; otherwise `USED`, `EXPIRED` or `INVALID`.
  Future<String> status(String? token) async {
    final clean = token?.trim() ?? '';
    if (clean.isEmpty) return 'INVALID';
    return _auth.passwordResetStatus(clean);
  }

  Future<void> confirm({required String? token, required String password}) async {
    final clean = token?.trim() ?? '';
    if (clean.isEmpty) throw const AppError(ErrorKind.validation, 'the link has no token', code: 'INVALID');
    await _auth.confirmPasswordReset(token: clean, password: password);
  }
}
