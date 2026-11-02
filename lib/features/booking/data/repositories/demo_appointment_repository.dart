import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/repositories/appointment_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

class DemoAppointmentRepository implements AppointmentRepository {
  const DemoAppointmentRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<List<TimeSlot>> slotsForDay(DateTime day) async {
    await _db.simulateLatency();
    return [
      for (var i = 0; i < DemoDatabase.slotsPerDay; i++)
        _db.slotAt(day, 8 + i ~/ 2, i.isEven ? 0 : 30),
    ];
  }

  @override
  Future<ReservationResult> reserve({
    required String patientId,
    required MedicalService service,
    required TimeSlot slot,
    String? reason,
  }) async {
    await _db.simulateLatency();
    final local = branchTime(slot.startUtc);
    final fresh = _db.slotAt(DateTime(local.year, local.month, local.day), local.hour, local.minute);
    final contested =
        local.hour == DemoDatabase.contestedHour && local.minute == DemoDatabase.contestedMinute;
    if (!fresh.isAvailable || contested) {
      _db.lostSlotIds.add(slot.id);
      return SlotTaken(slot);
    }
    final now = DateTime.now().toUtc();
    final appointment = Appointment(
      id: _db.nextAppointmentId(),
      patientId: patientId,
      service: service,
      slot: DemoDatabase.buildSlot(fresh.startUtc, SlotStatus.reserved),
      status: AppointmentStatus.pendingPayment,
      reason: reason,
      bookedAt: now,
      reservationExpiresAt: now.add(Appointment.reservationHold),
    );
    _db.appointments.add(appointment);
    return Reserved(appointment);
  }

  @override
  Future<List<Appointment>> appointmentsOf(String patientId) async {
    await _db.simulateLatency();
    return _db.appointments.where((a) => a.patientId == patientId).toList();
  }
}
