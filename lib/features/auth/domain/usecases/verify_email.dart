import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

/// Activates an account from the token of the link in the activation email.
class VerifyEmail {
  const VerifyEmail(this._auth);

  final AuthRepository _auth;

  Future<void> call(String? token) async {
    final clean = token?.trim() ?? '';
    if (clean.isEmpty) throw const AppError(ErrorKind.validation, 'the link has no token');
    await _auth.verifyEmail(clean);
  }
}
