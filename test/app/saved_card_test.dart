import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart';

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
    // Adding or managing cards needs the backend: the buttons are off, not fake.
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Agregar tarjeta')).onPressed, isNull);
  });

  testWidgets('API mode: with no card endpoint it says so and invents nothing', (tester) async {
    await useScreen(tester);
    final backend = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/auth/login':
          return _json({'access_token': 'jwt', 'token_type': 'Bearer', 'expires_in': 900}, 200);
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
