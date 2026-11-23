import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment_doctor.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/appointment_card.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

Widget _card({required bool processing}) {
  final db = DemoDatabase(latency: Duration.zero);
  final appointment = Appointment(
    id: 'c1',
    patientId: 'u1',
    service: db.services.first,
    slot: db.slotAt(DateTime.now(), 9, 0),
    status: AppointmentStatus.pendingPayment,
    bookedAt: DateTime.now().toUtc(),
  );
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AppointmentCard(
          appointment,
          processing: processing,
          onPay: () {},
          onCancel: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the doctor and the phone the API gives for them', (tester) async {
    final db = DemoDatabase(latency: Duration.zero);
    final appointment = Appointment(
      id: 'c2',
      patientId: 'u1',
      service: db.services.first,
      slot: db.slotAt(DateTime.now(), 9, 0),
      status: AppointmentStatus.confirmed,
      bookedAt: DateTime.now().toUtc(),
      doctor: const AppointmentDoctor(id: 'd1', name: 'Dra. Lucía Vera', phone: '2222-3333'),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AppointmentCard(appointment)))),
    );

    expect(find.textContaining('Dra. Lucía Vera · Tel. 2222-3333', findRichText: true), findsOneWidget);
  });

  testWidgets('a pending appointment offers to pay or cancel', (tester) async {
    await tester.pumpWidget(_card(processing: false));

    expect(find.text('Pagar ahora'), findsOneWidget);
    expect(find.text('Cancelar cita'), findsOneWidget);
    expect(find.textContaining('pendiente de procesamiento'), findsNothing);
  });

  testWidgets(
    'once the payment is sent there is no pay button, only the processing notice',
    (tester) async {
      await tester.pumpWidget(_card(processing: true));

      expect(find.text('Pagar ahora'), findsNothing);
      expect(find.text('Cancelar cita'), findsNothing);
      expect(
        find.textContaining('Pago pendiente de procesamiento'),
        findsOneWidget,
      );
      expect(find.text('Procesando pago'), findsOneWidget);
    },
  );
}
