/// What the patient declares about themselves. The backend uses it for the WHO 2024 hemoglobin
/// adjustments, and only the patient writes it. There is no endpoint to read it back.
class ClinicalProfile {
  const ClinicalProfile({required this.altitudeM, required this.smoker, this.cigarettesPerDay});

  /// Altitude of residence in metres above sea level.
  final int altitudeM;
  final bool smoker;

  /// Only meaningful (and only sent) for a smoker.
  final int? cigarettesPerDay;
}
