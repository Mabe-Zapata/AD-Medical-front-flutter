import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/doctor.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// Port to the scheduling API. Implementations throw `AppError` on failure.
abstract interface class AppointmentRepository {
  /// [day] is a branch calendar day; only its year/month/day are used. [doctorId] keeps only that doctor's slots.
  /// The real API only returns the free slots; the demo also returns the taken ones.
  Future<List<TimeSlot>> slotsForDay(DateTime day, {String? doctorId});

  /// The medical specialties the patient can choose from.
  Future<List<Specialty>> specialties();

  /// The doctors, optionally only those of [specialtyId].
  Future<List<Doctor>> doctors({int? specialtyId});

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

  /// Cancels an own appointment and releases its slot. [reason] is an optional free text the
  /// backend stores with the cancellation; blank means no reason.
  Future<Appointment> cancel({required String patientId, required String appointmentId, String? reason});
}
