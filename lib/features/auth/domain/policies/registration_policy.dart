import 'package:medicalbooking_portal/core/domain/personal_data.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';

/// The backend refuses passwords shorter than this (`MIN_PASSWORD_LENGTH` of its identity module).
const minPasswordLength = 12;

enum RegistrationProblem { firstName, lastName, email, document, phone, sex, birthDate, passwordLength }

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _cedula = RegExp(r'^\d{10}$');
final _passport = RegExp(r'^[A-Z0-9]{6,20}$');
final _phone = RegExp(r'^\+?\d{7,15}$');

/// Everything wrong with [account], already normalized. Empty means it can be sent. [now] is today, so a test
/// can fix it.
List<RegistrationProblem> registrationProblems(NewPatientAccount account, {DateTime? now}) => [
  if (account.firstName.isEmpty) RegistrationProblem.firstName,
  if (account.lastName.isEmpty) RegistrationProblem.lastName,
  if (!_email.hasMatch(account.email)) RegistrationProblem.email,
  if (!_documentIsValid(account)) RegistrationProblem.document,
  if (account.phone != null && !_phoneIsValid(account.phone!)) RegistrationProblem.phone,
  if (account.sex == null) RegistrationProblem.sex,
  if (account.birthDate == null || !isValidBirthDate(account.birthDate!, now ?? DateTime.now()))
    RegistrationProblem.birthDate,
  if (account.password.length < minPasswordLength) RegistrationProblem.passwordLength,
];

bool _documentIsValid(NewPatientAccount account) => switch (account.documentType) {
  'CEDULA' => _cedula.hasMatch(account.documentNumber),
  'PASAPORTE' => _passport.hasMatch(account.documentNumber),
  _ => false,
};

/// Spaces and dashes are allowed while typing; the API receives the digits.
bool _phoneIsValid(String raw) => _phone.hasMatch(raw.replaceAll(RegExp(r'[\s-]'), ''));

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
