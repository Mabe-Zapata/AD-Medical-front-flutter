/// What a person gives to create a patient account. The role is never part of it: the app that
/// registers decides it (here always patient) and the server must not accept it from the client.
class NewPatientAccount {
  const NewPatientAccount({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;

  /// International format, e.g. `+593991234567`.
  final String phone;
  final String password;

  NewPatientAccount normalized() => NewPatientAccount(
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: email.trim().toLowerCase(),
    phone: phone.replaceAll(RegExp(r'[\s-]'), ''),
    password: password,
  );
}
