import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/payment_methods_section.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> useScreen(WidgetTester tester) async {
    // The Ahem test font overflows rows that fit with the real font: layout is checked in the browser.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1800);
    addTearDown(tester.view.reset);
  }

  testWidgets('demo: the Pagos tab shows the saved card masked, with its brand and expiry', (tester) async {
    await useScreen(tester);
    await tester.pumpWidget(MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pagos'));
    await tester.pumpAndSettle();

    expect(find.text('Tarjeta guardada'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
    expect(find.textContaining('4242'), findsOneWidget);
    expect(find.text('VISA'), findsOneWidget);
    expect(find.text('09/28'), findsOneWidget);
    expect(find.textContaining('Tarjeta de ejemplo'), findsOneWidget);
    // A card is saved by paying with the consent box ticked, so there is no "add" button.
    expect(find.text('Agregar tarjeta'), findsNothing);
    expect(find.textContaining('Puedes guardar una tarjeta al pagar una cita'), findsOneWidget);

    // Removing it asks first, and then the screen says there is none.
    await tester.tap(find.text('Quitar tarjeta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quitar tu tarjeta guardada?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Quitar tarjeta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aún no tienes una tarjeta guardada'), findsOneWidget);
    expect(find.text('ACTIVA'), findsNothing);
  });

  testWidgets('an expired card is shown as expired, not as active', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PaymentMethodsSection(
              card: SavedCard(id: 'pm_1', brand: 'VISA', last4: '4242', expMonth: 1, expYear: 2020),
              holderName: 'María López',
              demo: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('VENCIDA'), findsOneWidget);
    expect(find.text('ACTIVA'), findsNothing);
  });

  testWidgets('API mode: with no card endpoint it says so and invents nothing', (tester) async {
    await useScreen(tester);
    final backend = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/auth/login':
          return _json({'access_token': 'jwt', 'token_type': 'Bearer', 'expires_in': 900}, 200);
        case '/api/v1/appointments':
          return _json({'items': []}, 200);
        case '/api/v1/lab/orders':
          return _json({'items': []}, 200);
        case '/api/v1/me/payment-methods':
          return _json({'items': []}, 200);
        case '/api/v1/me':
          return _json({'id': 'u1', 'roles': ['PACIENTE'], 'permissions': ['citas.reservar']}, 200);
      }
      return _json({'detail': 'unexpected'}, 404);
    });
    await tester.pumpWidget(
      MedicalBookingApp(
        dependencies: AppDependencies.api(apiBaseUrl: 'http://api.test/api/v1', client: backend, store: MemorySessionStore()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Correo electrónico'), 'paciente@demo.test');
    await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'whatever');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pagos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aún no tienes una tarjeta guardada'), findsOneWidget);
    expect(find.text('ACTIVA'), findsNothing);
    expect(find.textContaining('••••'), findsNothing);
  });
}
