import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/time_slot.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

Appointment _appointment(DateTime start, {AppointmentStatus status = AppointmentStatus.confirmed}) => Appointment(
  id: 'c1',
  patientId: 'u1',
  service: const MedicalService(id: 's1', name: 'Consulta', durationMin: 30, basePrice: 10),
  slot: TimeSlot(
    id: 'h1',
    startUtc: start,
    endUtc: start.add(const Duration(minutes: 30)),
    status: SlotStatus.reserved,
    doctorId: 'd1',
  ),
  status: status,
  bookedAt: start,
);

void main() {
  final start = DateTime.utc(2026, 11, 22, 14);

  test('an appointment can be cancelled until one hour after its start', () {
    final appointment = _appointment(start);

    expect(appointment.cancellableAt(start.add(const Duration(minutes: 60))), isTrue);
    expect(appointment.cancellableAt(start.add(const Duration(minutes: 61))), isFalse);
  });

  test('a finished or cancelled appointment is never cancellable', () {
    final cancelled = _appointment(start, status: AppointmentStatus.cancelled);

    expect(cancelled.cancellableAt(start.subtract(const Duration(hours: 1))), isFalse);
  });
}
