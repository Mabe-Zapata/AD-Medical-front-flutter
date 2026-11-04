import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';

String registrationMessage(RegistrationProblem problem) => switch (problem) {
  RegistrationProblem.firstName => 'Escribe tus nombres.',
  RegistrationProblem.lastName => 'Escribe tus apellidos.',
  RegistrationProblem.email => 'Escribe un correo válido.',
  RegistrationProblem.phone => 'Escribe un teléfono válido, solo números.',
  RegistrationProblem.passwordLength => 'Mínimo $minPasswordLength caracteres.',
};
