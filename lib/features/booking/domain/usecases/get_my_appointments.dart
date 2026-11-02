import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';

class GetMyAppointments {
  const GetMyAppointments(this._repository);

  final AppointmentRepository _repository;

  /// Most recently booked first.
  Future<List<Appointment>> call(String patientId) async {
    final appointments = await _repository.appointmentsOf(patientId);
    return [...appointments]..sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
  }
}
