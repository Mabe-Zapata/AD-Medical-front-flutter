import 'package:medicalbooking_portal/core/domain/personal_data.dart';

/// What a person gives to create a patient account. The role is never part of it: the app that
/// registers decides it (here always patient) and the server must not accept it from the client.
///
/// [sex] and [birthDate] are optional for the API (an older client keeps working), but the portal always asks
/// for them: the clinical interpretation of the results depends on both. The identity document is required by
/// the API; the phone is optional.
class NewPatientAccount {
  const NewPatientAccount({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.documentType,
    required this.documentNumber,
    this.phone,
    this.sex,
    this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  /// `CEDULA` or `PASAPORTE`, as the API names them; null until the person picks one.
  final String? documentType;
  final String documentNumber;
  final String? phone;
  final BiologicalSex? sex;
  final DateTime? birthDate;

  NewPatientAccount normalized() => NewPatientAccount(
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    email: email.trim().toLowerCase(),
    password: password,
    documentType: documentType,
    documentNumber: documentNumber.trim().toUpperCase(),
    phone: _phoneDigits(phone),
    sex: sex,
    birthDate: birthDate,
  );
}

/// The phone as the API takes it: no spaces or dashes; an empty phone means none.
String? _phoneDigits(String? raw) {
  final value = raw?.replaceAll(RegExp(r'[\s-]'), '') ?? '';
  return value.isEmpty ? null : value;
}
