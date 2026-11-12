import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/portal/presentation/widgets/profile_summary.dart';

Widget _wrap(Patient patient) => MaterialApp(home: Scaffold(body: ProfileSummary(patient)));

void main() {
  testWidgets('the personal data sit in one card, each with its label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Patient(
          id: 'u1',
          email: 'maria@example.test',
          firstName: 'María',
          lastName: 'López',
          phone: '+593 99 123 4567',
          documentType: 'CEDULA',
          documentNumber: '1712345678',
        ),
      ),
    );

    expect(find.text('María López'), findsOneWidget);
    expect(find.text('CORREO'), findsOneWidget);
    expect(find.text('maria@example.test'), findsOneWidget);
    expect(find.text('TELÉFONO'), findsOneWidget);
    expect(find.text('CÉDULA'), findsOneWidget);
    expect(find.text('1712345678'), findsOneWidget);
  });

  testWidgets('in the side column the same fields are stacked under the name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSummary(const Patient(id: 'u1', email: 'maria@example.test', phone: '+593 99 123 4567'), vertical: true),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('CORREO')).dy, lessThan(tester.getTopLeft(find.text('TELÉFONO')).dy));
    expect(tester.getTopLeft(find.text('CORREO')).dx, tester.getTopLeft(find.text('TELÉFONO')).dx);
  });

  testWidgets('a field the account does not have is left out', (tester) async {
    await tester.pumpWidget(_wrap(const Patient(id: 'u1', email: 'solo@example.test')));

    expect(find.text('CORREO'), findsOneWidget);
    expect(find.text('TELÉFONO'), findsNothing);
    expect(find.text('Mi cuenta'), findsOneWidget);
  });
}
