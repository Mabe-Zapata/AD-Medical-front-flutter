import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/slot_picker.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// The services `GET /services` would return: the same demo catalog, in the backend's JSON shape.
List<Map<String, dynamic>> _servicesJson() => [
  for (final s in DemoDatabase(latency: Duration.zero).services)
    {
      'id': s.id,
      'nombre': s.name,
      'duracion_min': s.durationMin,
      'precio_base': s.basePrice.toStringAsFixed(2),
      'moneda': s.currency,
      'especialidad_id': s.specialtyId,
      'requiere_orden_medica': s.requiresOrder,
    },
];

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// A real-API session: the account's name comes from GET /me, and the lab orders decide what a result review shows.
Future<void> _signIn(WidgetTester tester, MockClient backend) async {
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
  await tester.enterText(find.widgetWithText(TextField, 'Correo electrónico'), 'paciente@test.test');
  await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'whatever');
  await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
  await tester.pumpAndSettle();
}

MockClient _backend({required List<Map<String, dynamic>> orders}) => MockClient((request) async {
  switch (request.url.path) {
    case '/api/v1/auth/login':
      return _json({'access_token': 'jwt', 'token_type': 'Bearer', 'expires_in': 900}, 200);
    case '/api/v1/public/services':
      return _json({'items': _servicesJson()}, 200);
    case '/api/v1/me':
      return _json({
        'id': 'u1',
        'roles': ['PACIENTE'],
        'permissions': ['citas.reservar'],
        'nombre': 'María',
        'apellido': 'Pérez',
        'correo': 'paciente@test.test',
      }, 200);
    case '/api/v1/lab/orders':
      return _json({'items': orders}, 200);
    case '/api/v1/specialties':
      return _json({'items': [{'id': 1, 'nombre': 'Medicina general', 'descripcion': null}]}, 200);
    case '/api/v1/doctors':
      return _json({
        'items': [
          {
            'id': 'doc-1',
            'nombre': 'Dr. Andrés Mora',
            'especialidades': [{'id': 1, 'nombre': 'Medicina general'}],
            'duracion_cita_min': 30,
          },
        ],
      }, 200);
    case '/api/v1/availability':
      return _json({'items': []}, 200);
    default:
      if (request.url.path.startsWith('/api/v1/lab/orders/')) {
        final id = request.url.path.split('/').last;
        if (id == 'results') return _json({'items': []}, 200);
        final order = orders.firstWhere((o) => o['id'] == id);
        return _json({...order, 'prioridad': 'NORMAL', 'pruebas': []}, 200);
      }
      return _json({'items': []}, 200);
  }
});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the greeting and the account card read the name from GET /me', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);

    await _signIn(tester, _backend(orders: const []));

    expect(find.text('Bienvenido, María'), findsOneWidget);
    expect(find.text('María Pérez'), findsWidgets);
  });

  testWidgets('a result review without a medical order says so and offers no times', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);

    await _signIn(tester, _backend(orders: const []));
    await tester.tap(find.text('Agendar nueva cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisión de resultados con el médico'));
    await tester.pumpAndSettle();

    expect(find.textContaining('necesitas una orden médica'), findsOneWidget);
    expect(find.byType(SlotPicker), findsNothing);
  });

  testWidgets('a result review takes the doctor of the latest medical order and offers that doctor times', (
    tester,
  ) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);

    final order = {
      'id': 'ord-1',
      'paciente_id': 'p1',
      'medico_id': 'doc-1',
      'estado': 'COMPLETADA',
      'fecha': '2026-11-02T09:00:00Z',
    };
    await _signIn(tester, _backend(orders: [order]));
    await tester.tap(find.text('Agendar nueva cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisión de resultados con el médico'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Andrés Mora'), findsWidgets);
    expect(find.byType(SlotPicker), findsOneWidget);
  });
}
