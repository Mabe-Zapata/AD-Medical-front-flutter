import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/data/repositories/demo_appointment_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

void main() {
  // The demo offers its slots from 08:00 branch time, every 30 minutes.
  final day = DateTime(2026, 12, 7);

  Future<List<int>> branchHours(String serviceId) async {
    final repository = DemoAppointmentRepository(DemoDatabase(latency: Duration.zero));
    final slots = await repository.slotsForDay(day, serviceId: serviceId);
    return [for (final slot in slots) branchTime(slot.startUtc).hour];
  }

  test('sample collection is offered only in the morning window, until 10:00', () async {
    final hours = await branchHours('svc-blood');

    expect(hours, isNotEmpty);
    expect(hours.every((hour) => hour >= 8 && hour < 10), isTrue);
  });

  test('a consultation is offered only in the afternoon window, from 12:00', () async {
    final hours = await branchHours('svc-consult');

    expect(hours, isNotEmpty);
    expect(hours.every((hour) => hour >= 12 && hour < 17), isTrue);
  });
}
