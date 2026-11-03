import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// Port to the scheduling API. Implementations throw `AppError` on failure.
abstract interface class AppointmentRepository {
  /// [day] is a branch calendar day; only its year/month/day are used.
  /// The real API only returns the free slots; the demo also returns the taken ones.
  Future<List<TimeSlot>> slotsForDay(DateTime day);

  /// Must re-validate availability: the slot may have been taken since it was listed.
  Future<ReservationResult> reserve({
    required String patientId,
    required MedicalService service,
    required TimeSlot slot,
    String? reason,
  });

  /// Appointments the patient made. The real API has no listing, so this only knows the ones
  /// created since the app started.
  Future<List<Appointment>> appointmentsOf(String patientId);

  /// Cancels an own appointment and releases its slot.
  Future<Appointment> cancel({required String patientId, required String appointmentId});
}
