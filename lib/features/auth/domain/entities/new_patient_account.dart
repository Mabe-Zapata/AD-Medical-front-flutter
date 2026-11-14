import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// What a person gives to create a patient account. The role is never part of it: the app that
/// registers decides it (here always patient) and the server must not accept it from the client.
///
/// [sex] and [birthDate] are optional for the API (an older client keeps working), but the portal always asks
/// for them: the clinical interpretation of the results depends on both.
class NewPatientAccount {
  const NewPatientAccount({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.sex,
    this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final BiologicalSex? sex;
  final DateTime? birthDate;

  NewPatientAccount normalized() => NewPatientAccount(
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: email.trim().toLowerCase(),
    password: password,
    sex: sex,
    birthDate: birthDate,
  );
}
