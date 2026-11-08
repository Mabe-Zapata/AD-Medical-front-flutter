import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';

/// The backend refuses passwords shorter than this (`MIN_PASSWORD_LENGTH` of its identity module).
const minPasswordLength = 12;

enum RegistrationProblem { firstName, lastName, email, passwordLength }

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Everything wrong with [account], already normalized. Empty means it can be sent.
List<RegistrationProblem> registrationProblems(NewPatientAccount account) => [
  if (account.firstName.isEmpty) RegistrationProblem.firstName,
  if (account.lastName.isEmpty) RegistrationProblem.lastName,
  if (!_email.hasMatch(account.email)) RegistrationProblem.email,
  if (account.password.length < minPasswordLength) RegistrationProblem.passwordLength,
];

/// 0 (empty) to 4 (strong). Advisory only: the one hard rule is [minPasswordLength].
int passwordStrength(String password) {
  if (password.isEmpty) return 0;
  var score = 0;
  if (password.length >= minPasswordLength) score++;
  if (RegExp('[a-z]').hasMatch(password) && RegExp('[A-Z]').hasMatch(password)) score++;
  if (RegExp('[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password) || password.length >= 16) score++;
  return score;
}
