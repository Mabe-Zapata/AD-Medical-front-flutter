import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/next_appointment_card.dart';
import 'package:medicalbooking_portal/features/portal/presentation/widgets/summary_tiles.dart';
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
      body: SingleChildScrollView(child: NextAppointmentCard(appointment, processing: processing, onPay: () {}, onCancel: () {})),
    ),
  );
}

void main() {
  testWidgets('the next appointment offers to pay and cancel', (tester) async {
    await tester.pumpWidget(_card(processing: false));

    expect(find.text('TU PRÓXIMA CITA'), findsOneWidget);
    expect(find.text('Pagar ahora'), findsOneWidget);
    expect(find.text('Cancelar cita'), findsOneWidget);
  });

  testWidgets('once the payment is sent it shows the processing notice and no buttons', (tester) async {
    await tester.pumpWidget(_card(processing: true));

    expect(find.text('Pagar ahora'), findsNothing);
    expect(find.text('Cancelar cita'), findsNothing);
    expect(find.textContaining('Pago pendiente de procesamiento'), findsOneWidget);
  });

  testWidgets('each summary tile shows its count and works as a shortcut', (tester) async {
    var taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryTiles(
            toPay: 3,
            confirmed: 1,
            resultsReady: 2,
            onToPay: () => taps.add('pay'),
            onConfirmed: () => taps.add('ok'),
            onResults: () => taps.add('results'),
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Por pagar'));
    await tester.tap(find.text('Resultados listos'));

    expect(taps, ['pay', 'results']);
  });
}
