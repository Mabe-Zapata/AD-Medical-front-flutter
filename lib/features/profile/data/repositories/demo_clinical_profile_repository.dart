import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/repositories/clinical_profile_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoClinicalProfileRepository implements ClinicalProfileRepository {
  const DemoClinicalProfileRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<void> save(ClinicalProfile profile) => _db.simulateLatency();

  @override
  Future<ClinicalProfile?> read() async => null; // the demo starts every visit undeclared
}
