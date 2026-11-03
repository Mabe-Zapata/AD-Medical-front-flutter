import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<IssuedToken> login({required String email, required String password}) async {
    await _db.simulateLatency();
    if (email != DemoDatabase.demoEmail || password != DemoDatabase.demoPassword) {
      throw const AppError(ErrorKind.invalidCredentials, 'invalid credentials');
    }
    return const IssuedToken(token: 'demo-token', expiresIn: Duration(minutes: 15));
  }

  @override
  Future<Patient> fetchProfile({required String token, required String email}) async => _db.patient;
}
