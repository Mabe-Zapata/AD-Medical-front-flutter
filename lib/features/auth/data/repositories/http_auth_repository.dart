import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
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

  /// `POST /auth/register`: public, answers 202 whatever the email. The role is not sent; the server fixes it
  /// to patient, and it rejects any field it does not know (so no phone).
  @override
  Future<void> register(NewPatientAccount account) async {
    await _api.post(
      '/auth/register',
      body: {
        'email': account.email,
        'password': account.password,
        'first_name': account.firstName,
        'last_name': account.lastName,
      },
      authenticated: false,
    );
  }

  @override
  Future<void> verifyEmail(String token) async {
    await _api.get('/auth/verify-email', query: {'token': token});
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
