/// Same limits as the backend (`clinical_profile.py`); checking here gives a clearer message.
/// Highest altitude the WHO 2024 haemoglobin table covers (its last band ends at 4999 m). Above it the
/// adjustment is unknown, so a higher value could never be interpreted; the app refuses it up front.
const maxAltitudeM = 4999;
const maxCigarettesPerDay = 200;

enum ProfileProblem { altitude, smoking, cigarettes }

/// What is wrong with the declared data. Null means the person has not answered yet. Empty result
/// means it can be sent: the backend requires altitude and smoking, and a smoker's cigarettes per day. Sex and birth
/// date were given at sign-up and are not asked again.
List<ProfileProblem> profileProblems({int? altitudeM, bool? smoker, int? cigarettes}) => [
  if (altitudeM == null || altitudeM < 0 || altitudeM > maxAltitudeM) ProfileProblem.altitude,
  if (smoker == null) ProfileProblem.smoking,
  if (smoker == true && (cigarettes == null || cigarettes < 0 || cigarettes > maxCigarettesPerDay))
    ProfileProblem.cigarettes,
];
