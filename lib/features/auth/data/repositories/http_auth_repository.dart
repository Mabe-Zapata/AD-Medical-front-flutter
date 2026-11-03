import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<IssuedToken> login({required String email, required String password}) async {
    final json =
        await _api.post('/auth/login', body: {'email': email, 'password': password}, authenticated: false)
            as Map<String, dynamic>;
    return IssuedToken(
      token: json['access_token'] as String,
      expiresIn: Duration(seconds: json['expires_in'] as int),
    );
  }

  @override
  Future<Patient> fetchProfile({required String token, required String email}) async {
    final json = await _api.get('/me', bearer: token) as Map<String, dynamic>;
    return Patient(
      id: json['id'] as String,
      email: email,
      roles: List<String>.from(json['roles'] as List),
      permissions: List<String>.from(json['permissions'] as List),
    );
  }
}
