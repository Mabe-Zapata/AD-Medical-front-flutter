import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/usecases/load_clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/usecases/save_clinical_profile.dart';

/// Keeps what each patient declared: read from the backend on entry, and updated when they save.
class ClinicalProfileController extends ChangeNotifier {
  ClinicalProfileController({required this._save, required this._load});

  final SaveClinicalProfile _save;
  final LoadClinicalProfile _load;
  final _saved = <String, ClinicalProfile>{};

  ClinicalProfile? of(String patientId) => _saved[patientId];

  /// Asks the backend what the patient already declared. A failure keeps asking: it is not worth an error.
  Future<void> load(String patientId) async {
    try {
      final profile = await _load();
      if (profile == null || _saved.containsKey(patientId)) return;
      _saved[patientId] = profile;
      notifyListeners();
    } on AppError {
      // The prompt stays visible and the patient can still declare it.
    }
  }

  /// Throws `AppError` when the backend refuses the data.
  Future<void> save(String patientId, ClinicalProfile profile) async {
    await _save(profile);
    _saved[patientId] = profile;
    notifyListeners();
  }
}
