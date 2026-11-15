import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';

String registrationMessage(RegistrationProblem problem) => switch (problem) {
  RegistrationProblem.firstName => 'Escribe tus nombres.',
  RegistrationProblem.lastName => 'Escribe tus apellidos.',
  RegistrationProblem.email => 'Escribe un correo válido.',
  RegistrationProblem.document => 'Elige el tipo y escribe el número: cédula de 10 dígitos o pasaporte de 6 a 20 caracteres.',
  RegistrationProblem.phone => 'El teléfono debe tener entre 7 y 15 dígitos.',
  RegistrationProblem.sex => 'Elige una opción.',
  RegistrationProblem.birthDate => 'Elige una fecha de nacimiento válida.',
  RegistrationProblem.passwordLength => 'Mínimo $minPasswordLength caracteres.',
};
