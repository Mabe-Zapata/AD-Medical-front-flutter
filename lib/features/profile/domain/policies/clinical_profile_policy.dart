import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// Same limits as the backend (`clinical_profile.py`); checking here gives a clearer message.
const maxAltitudeM = 8848;
const maxCigarettesPerDay = 200;

enum ProfileProblem { altitude, smoking, cigarettes, sex, birthDate }

/// What is wrong with the declared data. Null means the person has not answered yet. Empty result
/// means it can be sent: the backend requires altitude and smoking, and a smoker's cigarettes per day; the portal
/// also requires sex and birth date, which the shadow findings need. [now] is today, so a test can fix it.
List<ProfileProblem> profileProblems({
  int? altitudeM,
  bool? smoker,
  int? cigarettes,
  BiologicalSex? sex,
  DateTime? birthDate,
  DateTime? now,
}) => [
  if (altitudeM == null || altitudeM < 0 || altitudeM > maxAltitudeM) ProfileProblem.altitude,
  if (smoker == null) ProfileProblem.smoking,
  if (smoker == true && (cigarettes == null || cigarettes < 0 || cigarettes > maxCigarettesPerDay))
    ProfileProblem.cigarettes,
  if (sex == null) ProfileProblem.sex,
  if (birthDate == null || !isValidBirthDate(birthDate, now ?? DateTime.now())) ProfileProblem.birthDate,
];
