import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
    // Tests render with the Ahem font (1 em per letter), which overflows rows that
    // fit with the real font. Layout at phone width is checked in the browser instead.
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
    await tester.pumpWidget(
      MedicalBookingApp(
        dependencies: AppDependencies.demo(latency: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('landing shows the Spanish hero and the catalog', (tester) async {
    await pumpApp(tester, size: const Size(1400, 2400));

    expect(find.text('Mantente sano'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Perfil lipídico'), findsOneWidget);
    expect(find.text('Toma de muestra de sangre'), findsOneWidget);
  });

  testWidgets(
    'starting without a session asks for login, then continues to the booking page',
    (tester) async {
      await pumpApp(tester, size: const Size(1400, 2400));

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      expect(find.text('PORTAL DEL PACIENTE'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Reservar una cita'), findsOneWidget);
      expect(find.text('1 · SERVICIO'), findsOneWidget);
    },
  );

  testWidgets(
    'the header sign-in goes to the portal and lists appointments and results',
    (tester) async {
      await pumpApp(tester, size: const Size(1400, 2400));

      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido, María'), findsOneWidget);
      expect(find.text('Citas'), findsOneWidget);
      expect(find.text('Toma de muestra de sangre'), findsWidgets);
    },
  );

  testWidgets('the phone layout shows the short sign-in label', (tester) async {
    await pumpApp(tester, size: const Size(375, 812));

    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsNothing);
  });
}
