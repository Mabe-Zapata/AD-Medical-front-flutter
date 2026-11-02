import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<Patient?> signIn({required String email, required String password}) async {
    await _db.simulateLatency();
    if (email != DemoDatabase.demoEmail || password != DemoDatabase.demoPassword) return null;
    _db.signedIn = true;
    return _db.patient;
  }

  @override
  Future<void> signOut() async {
    _db.signedIn = false;
  }
}
