import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/policies/clinical_profile_policy.dart';
import 'package:medicalbooking_portal/features/profile/domain/repositories/clinical_profile_repository.dart';

class SaveClinicalProfile {
  const SaveClinicalProfile(this._repository);

  final ClinicalProfileRepository _repository;

  Future<void> call(ClinicalProfile profile) async {
    final problems = profileProblems(
      altitudeM: profile.altitudeM,
      smoker: profile.smoker,
      cigarettes: profile.cigarettesPerDay,
    );
    if (problems.isNotEmpty) throw AppError(ErrorKind.validation, problems.map((p) => p.name).join(', '));
    await _repository.save(profile);
  }
}
