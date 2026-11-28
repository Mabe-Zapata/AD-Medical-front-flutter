import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/repositories/clinical_profile_repository.dart';

class LoadClinicalProfile {
  const LoadClinicalProfile(this._repository);

  final ClinicalProfileRepository _repository;

  Future<ClinicalProfile?> call() => _repository.read();
}
