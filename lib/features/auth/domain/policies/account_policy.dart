const patientRole = 'PACIENTE';

/// The patient portal is for patients. Staff use the Angular system instead.
bool isPatientAccount(Iterable<String> roles) => roles.contains(patientRole);
