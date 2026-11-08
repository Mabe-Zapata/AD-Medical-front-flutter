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

  testWidgets('API mode: signs in, lists the free slots of a day and returns to login when the token is rejected', (
    tester,
  ) async {
    // Same as app_flow_test: the Ahem test font overflows rows that fit with the real font.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);

    var tokenRejected = false;
    final requests = <String>[];
    final backend = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      switch (request.url.path) {
        case '/api/v1/auth/login':
          return _json({'access_token': 'jwt', 'token_type': 'Bearer', 'expires_in': 900}, 200);
        case '/api/v1/me':
          return _json({'id': 'u1', 'roles': ['PACIENTE'], 'permissions': ['citas.reservar']}, 200);
        case '/api/v1/availability':
          if (tokenRejected) return _json({'detail': 'Authentication required'}, 401);
          return _json({
            'items': [
              {
                'horario_id': 'slot-1',
                'medico_id': 'doc-1',
                // 14:00 UTC is 09:00 at the branch (UTC-5).
                'inicio_utc': DateTime.now().toUtc().add(const Duration(days: 1)).copyWith(hour: 14, minute: 0, second: 0, millisecond: 0, microsecond: 0).toIso8601String(),
                'fin_utc': DateTime.now().toUtc().add(const Duration(days: 1)).copyWith(hour: 14, minute: 30, second: 0, millisecond: 0, microsecond: 0).toIso8601String(),
              },
            ],
          }, 200);
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
    // The real API has no demo account: the form starts empty and says nothing about a demo.
    expect(find.textContaining('Cuenta demo'), findsNothing);
    expect(find.textContaining('Versión demo'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Correo electrónico'), 'paciente@demo.test');
    await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'whatever');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.textContaining('Aquí aparecen las citas que reservaste'), findsOneWidget);

    await tester.tap(find.text('Nueva cita'));
    await tester.pumpAndSettle();
    expect(requests, contains('GET /api/v1/availability'));

    // Pick another day: the next availability call is rejected as expired.
    tokenRejected = true;
    await tester.tap(find.byType(ChoiceChip).at(2));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
  testWidgets('API mode: the sign-up sends only the fields the backend accepts and asks to check the email', (
    tester,
  ) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);

    final bodies = <Map<String, dynamic>>[];
    final backend = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/register') {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return _json({'message': 'Si el correo es válido, recibirás un enlace.'}, 202);
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

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    for (final entry in {
      'Nombres': 'Ana',
      'Apellidos': 'Pérez',
      'Correo electrónico': 'Ana@Demo.test',
      'Contraseña': 'una-clave-larga-1',
      'Confirmar': 'una-clave-larga-1',
    }.entries) {
      await tester.enterText(find.widgetWithText(TextField, entry.key), entry.value);
    }
    for (final index in [0, 1]) {
      await tester.ensureVisible(find.byType(CheckboxListTile).at(index));
      await tester.tap(find.byType(CheckboxListTile).at(index));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Revisa tu correo'), findsOneWidget);
    // `additionalProperties: false` on the backend: any extra field (a phone, a role) would be a 422.
    expect(bodies.single, {
      'email': 'ana@demo.test',
      'password': 'una-clave-larga-1',
      'first_name': 'Ana',
      'last_name': 'Pérez',
    });
  });

  testWidgets('API mode: the activation link calls the verification endpoint once with its token', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.defaultRouteNameTestValue = '/verificar?token=abc123';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

    final calls = <Uri>[];
    var accepted = true;
    final backend = MockClient((request) async {
      calls.add(request.url);
      return accepted
          ? _json({'verified': true}, 200)
          : _json({'detail': 'The link is invalid, already used or expired', 'correlation_id': 'c-5'}, 422);
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

    expect(find.text('Tu cuenta está activa'), findsOneWidget);
    expect(calls.map((u) => u.toString()), ['http://api.test/api/v1/auth/verify-email?token=abc123']);

    // A second opening of the same single-use link: the server refuses and the page says so.
    accepted = false;
    tester.platformDispatcher.defaultRouteNameTestValue = '/verificar?token=abc123';
    await tester.pumpWidget(const SizedBox());
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

    expect(find.text('No pudimos activar tu cuenta'), findsOneWidget);
    expect(find.textContaining('El enlace no es válido, ya se usó o venció.'), findsOneWidget);
    expect(find.textContaining('c-5'), findsOneWidget);
  });
}
