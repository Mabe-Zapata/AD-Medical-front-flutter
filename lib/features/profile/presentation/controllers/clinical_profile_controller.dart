import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/usecases/save_clinical_profile.dart';

/// Remembers what each patient declared while the page is open. The API has no endpoint to read the
/// profile, so after a reload the portal asks again instead of claiming it is complete.
class ClinicalProfileController extends ChangeNotifier {
  ClinicalProfileController({required this._save});

  final SaveClinicalProfile _save;
  final _saved = <String, ClinicalProfile>{};

  ClinicalProfile? of(String patientId) => _saved[patientId];

  /// Throws `AppError` when the backend refuses the data.
  Future<void> save(String patientId, ClinicalProfile profile) async {
    await _save(profile);
    _saved[patientId] = profile;
    notifyListeners();
  }
}
