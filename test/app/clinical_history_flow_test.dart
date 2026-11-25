import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> useScreen(WidgetTester tester, Size size) async {
    // The Ahem test font overflows rows that fit with the real font: layout is checked in the browser.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) {
        original?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> tapText(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> signInToDemoPortal(WidgetTester tester) async {
    await tester.pumpWidget(
      MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tester.view.physicalSize.width < 900 ? 'ENTRAR' : 'INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the patient opens the history, sees what was recorded, and a declaration waits for the doctor',
    (tester) async {
      await useScreen(tester, const Size(1400, 900));
      await signInToDemoPortal(tester);

      await tapText(tester, find.text('Mi historia clínica'));
      expect(find.text('Historia clínica'), findsOneWidget);
      expect(find.text('Penicilina'), findsOneWidget, reason: 'the allergies tab opens first');

      await tapText(tester, find.text('Antecedentes'));
      await tapText(tester, find.text('Declarar'));
      expect(
        find.text('Escribe una descripción (500 caracteres como máximo).'),
        findsOneWidget,
        reason: 'an empty description is explained under the field, before any request',
      );

      await tester.enterText(find.widgetWithText(TextField, 'Descripción'), 'Migraña');
      await tapText(tester, find.text('Declarar'));
      expect(find.text('Migraña'), findsOneWidget);
      expect(find.text('Pendiente de confirmar'), findsWidgets);

      await tapText(tester, find.text('Bitácora'));
      expect(find.text('Antecedente registrado'), findsOneWidget, reason: 'the log names what changed, not who');
    },
  );
}
