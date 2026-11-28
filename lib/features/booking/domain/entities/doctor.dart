/// especialidades.id of the catalogue of medical specialties.
class Specialty {
  const Specialty({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;
}

/// medicos, as a patient may see them: name and specialties. Never the professional registration or contact details.
class Doctor {
  const Doctor({required this.id, required this.name, required this.specialties, required this.durationMin});

  final String id;
  final String name;
  final List<Specialty> specialties;

  /// How long one appointment with this doctor takes.
  final int durationMin;

  /// `Hematología · Medicina general`, for the patient to read.
  String get specialtyLabel => specialties.map((s) => s.name).join(' · ');
}
