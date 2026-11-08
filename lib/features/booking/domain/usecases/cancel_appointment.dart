import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';

class CancelAppointment {
  const CancelAppointment(this._repository);

  final AppointmentRepository _repository;

  Future<Appointment> call({required String patientId, required Appointment appointment}) {
    if (!appointment.holdsSlot) {
      throw const AppError(ErrorKind.conflict, 'only an active appointment can be cancelled');
    }
    return _repository.cancel(patientId: patientId, appointmentId: appointment.id);
  }
}
