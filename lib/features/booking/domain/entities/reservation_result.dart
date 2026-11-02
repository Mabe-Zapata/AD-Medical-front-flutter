import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';

sealed class ReservationResult {
  const ReservationResult();
}

class Reserved extends ReservationResult {
  const Reserved(this.appointment);

  final Appointment appointment;
}

/// The slot was lost to a concurrent booking (or was never free).
class SlotTaken extends ReservationResult {
  const SlotTaken(this.slot);

  final TimeSlot slot;
}
