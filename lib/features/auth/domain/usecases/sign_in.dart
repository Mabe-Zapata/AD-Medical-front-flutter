import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Patient?> call({required String email, required String password}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) return Future.value();
    return _repository.signIn(email: normalized, password: password);
  }
}
