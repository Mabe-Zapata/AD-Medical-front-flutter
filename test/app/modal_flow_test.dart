import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/slot_picker.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
    // The Ahem test font overflows rows that fit with the real font: layout is checked in the browser.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
  }

  Future<void> tapText(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillRegistration(WidgetTester tester, {String password = 'una-clave-larga-1'}) async {
    await type(tester, 'Nombres', 'Ana');
    await type(tester, 'Apellidos', 'Pérez');
    await type(tester, 'Correo electrónico', 'ana@demo.test');
    await type(tester, 'Teléfono móvil', '99 123 4567');
    await type(tester, 'Contraseña', password);
    await type(tester, 'Confirmar contraseña', password);
    await tapText(tester, find.byType(CheckboxListTile));
  }

  /// Picks tomorrow and its first free time, inside the booking modal.
  Future<void> pickFirstSlot(WidgetTester tester) async {
    await tapText(tester, find.byType(ChoiceChip).at(1));
    await tapText(tester, find.descendant(of: find.byType(SlotPicker), matching: find.byType(OutlinedButton)).first);
  }

  Future<void> signInWithDemoAccount(WidgetTester tester, String entryLabel) async {
    await tester.tap(find.text(entryLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  group('sign-up modal', () {
    testWidgets('creates a patient account and signs in', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('NUEVA CUENTA'), findsOneWidget);

      await fillRegistration(tester);
      await tapText(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

      expect(find.text('Hola, Ana'), findsOneWidget);
    });

    testWidgets('explains what is missing and does not submit', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      await type(tester, 'Contraseña', 'corta');
      await tapText(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

      expect(find.text('Escribe tus nombres.'), findsOneWidget);
      expect(find.text('Escribe un correo válido.'), findsOneWidget);
      expect(find.text('Mínimo 12 caracteres.'), findsOneWidget);
      expect(find.text('Debes aceptarlos para crear la cuenta.'), findsOneWidget);
      expect(find.textContaining('Hola,'), findsNothing);
    });

    testWidgets('checks that both passwords match', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      await type(tester, 'Contraseña', 'una-clave-larga-1');
      await type(tester, 'Confirmar contraseña', 'otra-clave-larga-2');
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    testWidgets('switches between sign-in and sign-up without leaving the modal', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      await tapText(tester, find.widgetWithText(TextButton, 'Crear cuenta').last);
      expect(find.widgetWithText(TextField, 'Nombres'), findsOneWidget);

      await tapText(tester, find.text('Inicia sesión'));
      expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Nombres'), findsNothing);
    });

    testWidgets('the close button returns to the page underneath', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Contraseña'), findsNothing);
      expect(find.text('Mantente sano'), findsOneWidget);
    });
  });

  group('booking modal', () {
    testWidgets('reserves in two steps and lands on the portal', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));
      await signInWithDemoAccount(tester, 'INICIAR SESIÓN');

      await tapText(tester, find.text('Nueva cita'));
      expect(find.text('PASO 1 DE 2: SERVICIO Y HORARIO'), findsOneWidget);

      await pickFirstSlot(tester);
      await tapText(tester, find.text('Continuar'));
      expect(find.text('PASO 2 DE 2: CONFIRMACIÓN'), findsOneWidget);
      expect(find.text('Resumen'), findsOneWidget);

      await tapText(tester, find.text('Confirmar reserva'));
      expect(find.textContaining('creada'), findsOneWidget);
      expect(find.text('Hola, María'), findsOneWidget);
    });

    testWidgets('cannot continue until a time is chosen, and can go back', (tester) async {
      await pumpApp(tester, size: const Size(1400, 900));
      await signInWithDemoAccount(tester, 'INICIAR SESIÓN');
      await tapText(tester, find.text('Nueva cita'));

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('PASO 1 DE 2: SERVICIO Y HORARIO'), findsOneWidget);

      await pickFirstSlot(tester);
      await tapText(tester, find.text('Continuar'));
      await tapText(tester, find.text('Cambiar servicio u hora'));
      expect(find.text('PASO 1 DE 2: SERVICIO Y HORARIO'), findsOneWidget);
    });
  });

  group('phone layout', () {
    testWidgets('the sign-up is a full-screen sheet and works end to end', (tester) async {
      await pumpApp(tester, size: const Size(375, 812));

      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();
      // The brand bullets only exist in the wide layout.
      expect(find.textContaining('Reserva tu cita de laboratorio en minutos'), findsNothing);
      expect(find.text('Tus citas y resultados, en un solo lugar.'), findsOneWidget);

      await tapText(tester, find.widgetWithText(TextButton, 'Crear cuenta'));
      await fillRegistration(tester);
      await tapText(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

      expect(find.text('Hola, Ana'), findsOneWidget);
    });

    testWidgets('booking works on a phone', (tester) async {
      await pumpApp(tester, size: const Size(375, 812));
      await signInWithDemoAccount(tester, 'ENTRAR');

      await tapText(tester, find.text('Nueva cita'));
      await pickFirstSlot(tester);
      await tapText(tester, find.text('Continuar'));
      await tapText(tester, find.text('Confirmar reserva'));

      expect(find.textContaining('creada'), findsOneWidget);
    });
  });
}
