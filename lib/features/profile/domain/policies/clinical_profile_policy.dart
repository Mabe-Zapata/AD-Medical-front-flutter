/// Same limits as the backend (`clinical_profile.py`); checking here gives a clearer message.
const maxAltitudeM = 8848;
const maxCigarettesPerDay = 200;

enum ProfileProblem { altitude, smoking, cigarettes }

/// What is wrong with the declared data. Null means the person has not answered yet. Empty result
/// means it can be sent: the backend requires altitude and smoking, and a smoker's cigarettes per day.
List<ProfileProblem> profileProblems({int? altitudeM, bool? smoker, int? cigarettes}) => [
  if (altitudeM == null || altitudeM < 0 || altitudeM > maxAltitudeM) ProfileProblem.altitude,
  if (smoker == null) ProfileProblem.smoking,
  if (smoker == true && (cigarettes == null || cigarettes < 0 || cigarettes > maxCigarettesPerDay))
    ProfileProblem.cigarettes,
];
