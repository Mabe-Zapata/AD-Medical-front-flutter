/// usuarios + pacientes
class Patient {
  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.documentType,
    this.documentNumber,
    this.birthDate,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? documentType;
  final String? documentNumber;
  final DateTime? birthDate;

  String get fullName => '$firstName $lastName';
}
