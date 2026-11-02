import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

class ReserveAppointment {
  const ReserveAppointment(this._repository);

  /// citas.motivo is nvarchar(500).
  static const maxReasonLength = 500;

  final AppointmentRepository _repository;

  Future<ReservationResult> call({
    required Patient patient,
    required MedicalService service,
    required TimeSlot slot,
    String? reason,
  }) {
    final trimmed = reason?.trim();
    if (trimmed != null && trimmed.length > maxReasonLength) {
      throw ArgumentError.value(reason, 'reason', 'longer than $maxReasonLength characters');
    }
    if (!slot.isAvailable) return Future.value(SlotTaken(slot));
    return _repository.reserve(
      patientId: patient.id,
      service: service,
      slot: slot,
      reason: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
  }
}
