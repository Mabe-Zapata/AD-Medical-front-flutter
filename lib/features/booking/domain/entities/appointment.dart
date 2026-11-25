import 'package:medicalbooking_portal/features/booking/domain/entities/appointment_doctor.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

/// citas.estado
enum AppointmentStatus { pendingPayment, confirmed, completed, cancelled, expired, noShow }

/// citas
class Appointment {
  /// How long a pending-payment reservation holds its slot.
  static const reservationHold = Duration(minutes: 15);

  const Appointment({
    required this.id,
    required this.patientId,
    required this.service,
    required this.slot,
    required this.status,
    required this.bookedAt,
    this.reason,
    this.reservationExpiresAt,
    this.doctor,
    this.paymentId,
    this.refundState,
  });

  final String id;
  final String patientId;
  final MedicalService service;
  final TimeSlot slot;
  final AppointmentStatus status;
  final String? reason;
  final DateTime bookedAt;
  final DateTime? reservationExpiresAt;

  /// Who attends the appointment, as the listing says it; null when the API does not name a doctor.
  final AppointmentDoctor? doctor;

  /// The confirmed payment of the appointment, as the listing says it; null when it was not paid.
  final String? paymentId;

  /// The state of the newest refund (`PENDIENTE`, `PROCESADO`, `FALLIDO`); null when there is none.
  final String? refundState;

  /// Patients and doctors may cancel until this long after the start; the API enforces the same rule.
  static const cancellationWindow = Duration(hours: 1);

  /// Active appointments hold their slot (see UX_citas_horario_activa).
  bool get holdsSlot =>
      status == AppointmentStatus.pendingPayment || status == AppointmentStatus.confirmed;

  /// Active and still inside the cancellation window at [now].
  bool cancellableAt(DateTime now) =>
      holdsSlot && !now.toUtc().isAfter(slot.startUtc.add(cancellationWindow));

  Appointment copyWith({AppointmentStatus? status, String? paymentId, String? refundState}) => Appointment(
    id: id,
    patientId: patientId,
    service: service,
    slot: slot,
    status: status ?? this.status,
    bookedAt: bookedAt,
    reason: reason,
    reservationExpiresAt: reservationExpiresAt,
    doctor: doctor,
    paymentId: paymentId ?? this.paymentId,
    refundState: refundState ?? this.refundState,
  );
}
