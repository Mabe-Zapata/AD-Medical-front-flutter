import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';

enum PasswordChangeProblem { currentMissing, newTooShort, newSameAsCurrent, confirmationMismatch }

/// What is wrong with a password change, checked before the API is called. The API repeats the rules
/// that matter (current password, length, difference) so this is only the early, friendly check.
Set<PasswordChangeProblem> passwordChangeProblems({
  required String current,
  required String next,
  required String confirmation,
}) => {
  if (current.isEmpty) PasswordChangeProblem.currentMissing,
  if (next.length < minPasswordLength) PasswordChangeProblem.newTooShort,
  if (next.isNotEmpty && next == current) PasswordChangeProblem.newSameAsCurrent,
  if (next != confirmation) PasswordChangeProblem.confirmationMismatch,
};
