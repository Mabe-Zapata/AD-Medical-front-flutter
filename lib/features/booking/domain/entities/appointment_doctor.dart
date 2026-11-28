/// The doctor of a listed appointment, with the contact data the patient needs to reach them.
class AppointmentDoctor {
  const AppointmentDoctor({required this.id, required this.name, this.registration, this.phone});

  final String id;
  final String name;

  /// Professional registration number; null when the API does not send it.
  final String? registration;

  /// Phone the doctor can be reached on; null when the API does not send it.
  final String? phone;
}
