import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

abstract interface class AppointmentRepository {
  /// [day] is a branch calendar day; only its year/month/day are used.
  Future<List<TimeSlot>> slotsForDay(DateTime day);

  /// Must re-validate availability: the slot may have been taken since it was listed.
  Future<ReservationResult> reserve({
    required String patientId,
    required MedicalService service,
    required TimeSlot slot,
    String? reason,
  });

  Future<List<Appointment>> appointmentsOf(String patientId);
}
