import 'package:medicalbooking_portal/features/booking/domain/entities/doctor.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';

/// The specialties the patient can pick from.
class ListSpecialties {
  const ListSpecialties(this._repository);

  final AppointmentRepository _repository;

  Future<List<Specialty>> call() => _repository.specialties();
}

/// The doctors of a specialty, sorted by name, so the list does not change between visits.
class ListDoctors {
  const ListDoctors(this._repository);

  final AppointmentRepository _repository;

  /// All doctors when no [specialty] is given (a result review looks its doctor up by id).
  Future<List<Doctor>> call([Specialty? specialty]) async {
    final doctors = await _repository.doctors(specialtyId: specialty?.id);
    return [...doctors]..sort((a, b) => a.name.compareTo(b.name));
  }
}
