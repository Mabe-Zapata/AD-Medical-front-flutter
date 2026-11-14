import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';

String registrationMessage(RegistrationProblem problem) => switch (problem) {
  RegistrationProblem.firstName => 'Escribe tus nombres.',
  RegistrationProblem.lastName => 'Escribe tus apellidos.',
  RegistrationProblem.email => 'Escribe un correo válido.',
  RegistrationProblem.sex => 'Elige una opción.',
  RegistrationProblem.birthDate => 'Elige una fecha de nacimiento válida.',
  RegistrationProblem.passwordLength => 'Mínimo $minPasswordLength caracteres.',
};
