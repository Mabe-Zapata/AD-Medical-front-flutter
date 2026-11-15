import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// What the patient declares about themselves: altitude and smoking, used for the WHO 2024 hemoglobin adjustments.
/// Sex and birth date come from the sign-up; they are kept as they are and not edited here.
class ClinicalProfile {
  const ClinicalProfile({
    required this.altitudeM,
    required this.smoker,
    this.sex,
    this.birthDate,
    this.cigarettesPerDay,
  });

  /// Altitude of residence in metres above sea level.
  final int altitudeM;
  final bool smoker;
  final BiologicalSex? sex;

  /// A calendar date (no time).
  final DateTime? birthDate;

  /// Only meaningful (and only sent) for a smoker.
  final int? cigarettesPerDay;
}
