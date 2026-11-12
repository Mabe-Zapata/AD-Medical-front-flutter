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

  Future<void> useScreen(WidgetTester tester, Size size) async {
    // The Ahem test font overflows rows that fit with the real font: layout is checked in the browser.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
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
    await tester.pumpWidget(MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)));
    await tester.pumpAndSettle();
    // The header says ENTRAR on a phone and INICIAR SESIÓN on a wide screen.
    await tester.tap(find.text(tester.view.physicalSize.width < 900 ? 'ENTRAR' : 'INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('the portal invites the patient to complete the profile, and shows it once saved', (tester) async {
    await useScreen(tester, const Size(1400, 900));
    await signInToDemoPortal(tester);
    expect(find.text('Completa tu perfil clínico'), findsOneWidget);

    await tapText(tester, find.text('Completar'));
    await tester.enterText(find.widgetWithText(TextField, 'Altitud de residencia (metros)'), '2850');
    await tapText(tester, find.text('No fumo'));
    await tapText(tester, find.text('Guardar perfil'));
    expect(find.text('Perfil guardado'), findsOneWidget);

    await tapText(tester, find.text('Volver a mi portal'));
    expect(find.text('Perfil clínico completo'), findsOneWidget);
    expect(find.textContaining('2850 m de altitud · no fumas'), findsOneWidget);
    expect(find.text('Completa tu perfil clínico'), findsNothing);
  });

  testWidgets('asks for what is missing and does not save', (tester) async {
    await useScreen(tester, const Size(1400, 900));
    await signInToDemoPortal(tester);
    await tapText(tester, find.text('Completar'));

    await tapText(tester, find.text('Guardar perfil'));

    expect(find.text('Escribe un número entre 0 y 8848.'), findsOneWidget);
    expect(find.text('Elige una opción.'), findsOneWidget);
    expect(find.text('Perfil guardado'), findsNothing);
  });

  testWidgets('a smoker must say how many cigarettes a day', (tester) async {
    await useScreen(tester, const Size(1400, 900));
    await signInToDemoPortal(tester);
    await tapText(tester, find.text('Completar'));
    await tester.enterText(find.widgetWithText(TextField, 'Altitud de residencia (metros)'), '100');
    await tapText(tester, find.text('Fumo'));

    await tapText(tester, find.text('Guardar perfil'));
    expect(find.text('Escribe un número entre 0 y 200.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Cigarrillos por día'), '8');
    await tapText(tester, find.text('Guardar perfil'));
    expect(find.text('Perfil guardado'), findsOneWidget);

    await tapText(tester, find.text('Volver a mi portal'));
    expect(find.textContaining('fumas 8 al día'), findsOneWidget);
  });

  testWidgets('reopening shows what was declared and works on a phone', (tester) async {
    await useScreen(tester, const Size(375, 812));
    await signInToDemoPortal(tester);
    await tapText(tester, find.text('Completar'));
    await tester.enterText(find.widgetWithText(TextField, 'Altitud de residencia (metros)'), '2850');
    await tapText(tester, find.text('No fumo'));
    await tapText(tester, find.text('Guardar perfil'));
    await tapText(tester, find.text('Volver a mi portal'));

    await tapText(tester, find.text('Editar'));

    final altitude = tester.widget<TextField>(find.widgetWithText(TextField, 'Altitud de residencia (metros)'));
    expect(altitude.controller!.text, '2850');
  });

  testWidgets('API mode: sends only the fields the backend accepts and explains a refusal in Spanish', (tester) async {
    await useScreen(tester, const Size(1400, 900));
    final bodies = <Map<String, dynamic>>[];
    var refuse = true;
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
        case '/api/v1/me/perfil-clinico':
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return refuse
              ? _json({'detail': 'Invalid fields: altitud_residencia_m', 'correlation_id': 'c-4'}, 422)
              : _json({}, 200);
      }
      return _json({'detail': 'unexpected'}, 404);
    });
    await tester.pumpWidget(
      MedicalBookingApp(
        dependencies: AppDependencies.api(
          apiBaseUrl: 'http://api.test/api/v1',
          client: backend,
          store: MemorySessionStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Correo electrónico'), 'paciente@demo.test');
    await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'whatever');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    await tapText(tester, find.text('Completar'));
    await tester.enterText(find.widgetWithText(TextField, 'Altitud de residencia (metros)'), '2850');
    await tapText(tester, find.text('No fumo'));
    await tapText(tester, find.text('Guardar perfil'));

    expect(find.textContaining('Revisa la altitud'), findsOneWidget);
    expect(find.textContaining('c-4'), findsOneWidget);
    expect(find.textContaining('Invalid fields'), findsNothing);

    refuse = false;
    await tapText(tester, find.text('Guardar perfil'));
    expect(find.text('Perfil guardado'), findsOneWidget);
    expect(bodies.last, {'altitud_residencia_m': 2850, 'fumador': false, 'cigarrillos_dia': null});
  });
}
