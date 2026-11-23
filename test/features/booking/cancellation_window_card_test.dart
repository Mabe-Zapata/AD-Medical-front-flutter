import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/appointment_card.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

Widget _card(DateTime start) {
  final db = DemoDatabase(latency: Duration.zero);
  final appointment = Appointment(
    id: 'c3',
    patientId: 'u1',
    service: db.services.first,
    slot: db.slotAt(start, 9, 0),
    status: AppointmentStatus.confirmed,
    bookedAt: start.toUtc(),
  );
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: AppointmentCard(appointment, onCancel: () {}))),
  );
}

void main() {
  testWidgets('an appointment more than an hour past its start offers no cancel', (tester) async {
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));

    await tester.pumpWidget(_card(twoHoursAgo));

    expect(find.text('Cancelar cita'), findsNothing);
  });
}
