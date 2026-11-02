import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/data/repositories/demo_appointment_repository.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/reservation_result.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_day_slots.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

void main() {
  late DemoDatabase db;
  late GetDaySlots getDaySlots;
  late ReserveAppointment reserve;
  late GetMyAppointments getMine;

  final day = branchToday().add(const Duration(days: 3));
  bool isContested(TimeSlot s) {
    final local = branchTime(s.startUtc);
    return local.hour == DemoDatabase.contestedHour && local.minute == DemoDatabase.contestedMinute;
  }

  setUp(() {
    db = DemoDatabase(latency: Duration.zero);
    final repository = DemoAppointmentRepository(db);
    getDaySlots = GetDaySlots(repository);
    reserve = ReserveAppointment(repository);
    getMine = GetMyAppointments(repository);
  });

  test('a reservation holds the slot as pending payment and blocks a second one', () async {
    final slot = (await getDaySlots(day)).firstWhere((s) => s.isAvailable && !isContested(s));

    final first = await reserve(patient: db.patient, service: db.services.first, slot: slot, reason: '  check-up ');
    expect(first, isA<Reserved>());
    final appointment = (first as Reserved).appointment;
    expect(appointment.status, AppointmentStatus.pendingPayment);
    expect(appointment.reason, 'check-up');

    final again = (await getDaySlots(day)).firstWhere((s) => s.id == slot.id);
    expect(again.status, SlotStatus.reserved);
    expect(await reserve(patient: db.patient, service: db.services.first, slot: slot), isA<SlotTaken>());
  });

  test('a slot that looks free can still be lost to a concurrent booking', () async {
    // The "busy" pattern depends on the day of the month, so look for a day where 10:30 is listed free.
    late final TimeSlot contested;
    late final DateTime contestedDay;
    for (var offset = 1; offset <= 10; offset++) {
      final candidate = branchToday().add(Duration(days: offset));
      final match = (await getDaySlots(candidate)).where((s) => s.isAvailable && isContested(s));
      if (match.isNotEmpty) {
        contested = match.first;
        contestedDay = candidate;
        break;
      }
    }

    final result = await reserve(patient: db.patient, service: db.services.first, slot: contested);

    expect(result, isA<SlotTaken>());
    expect((await getDaySlots(contestedDay)).firstWhere((s) => s.id == contested.id).isAvailable, isFalse);
  });

  test('an unavailable slot is rejected without calling the repository', () async {
    final taken = (await getDaySlots(day)).firstWhere((s) => !s.isAvailable);
    expect(await reserve(patient: db.patient, service: db.services.first, slot: taken), isA<SlotTaken>());
    expect(db.appointments.where((a) => a.slot.id == taken.id), isEmpty);
  });

  test('rejects a reason longer than the column allows', () async {
    final slot = (await getDaySlots(day)).firstWhere((s) => s.isAvailable && !isContested(s));
    final tooLong = 'x' * (ReserveAppointment.maxReasonLength + 1);
    expect(
      () => reserve(patient: db.patient, service: db.services.first, slot: slot, reason: tooLong),
      throwsArgumentError,
    );
  });

  test('my appointments are listed most recently booked first', () async {
    final mine = await getMine(db.patient.id);
    expect(mine, isNotEmpty);
    for (var i = 1; i < mine.length; i++) {
      expect(mine[i - 1].bookedAt.isAfter(mine[i].bookedAt), isTrue);
    }
    expect(await getMine('someone-else'), isEmpty);
  });
}
