import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';

/// Port to the patient's clinical profile. Implementations throw `AppError` on failure.
abstract interface class ClinicalProfileRepository {
  Future<void> save(ClinicalProfile profile);
}
