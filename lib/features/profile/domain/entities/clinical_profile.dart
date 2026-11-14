import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// What the patient declares about themselves. The backend uses altitude and smoking for the WHO 2024 hemoglobin
/// adjustments, and sex and birth date to pick the reference ranges and thresholds. Only the patient writes it.
/// A profile is complete only with all of it: the portal keeps asking until then.
class ClinicalProfile {
  const ClinicalProfile({
    required this.altitudeM,
    required this.smoker,
    required this.sex,
    required this.birthDate,
    this.cigarettesPerDay,
  });

  /// Altitude of residence in metres above sea level.
  final int altitudeM;
  final bool smoker;
  final BiologicalSex sex;

  /// A calendar date (no time).
  final DateTime birthDate;

  /// Only meaningful (and only sent) for a smoker.
  final int? cigarettesPerDay;
}
