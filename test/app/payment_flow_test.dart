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
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const serviceId = '11111111-1111-4111-8111-111111111111';

  Future<void> useScreen(WidgetTester tester, {String route = '/'}) async {
    tester.platformDispatcher.defaultRouteNameTestValue = route;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    // The Ahem test font overflows rows that fit with the real font: layout is checked in the browser.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);
  }

  Future<void> tapText(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('demo: paying a pending appointment confirms it', (tester) async {
    await useScreen(tester);
    await tester.pumpWidget(MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    await tapText(tester, find.text('Nueva cita'));
    await tapText(tester, find.byType(ChoiceChip).at(1));
    await tapText(tester, find.descendant(of: find.byType(SlotPicker), matching: find.byType(OutlinedButton)).first);
    await tapText(tester, find.text('Continuar'));
    await tapText(tester, find.text('Confirmar reserva'));
    expect(find.text('Pago pendiente'), findsOneWidget);

    await tapText(tester, find.text('Pagar ahora'));

    expect(find.text('Pago pendiente'), findsNothing);
    expect(find.text('Pagar ahora'), findsNothing);
    expect(find.textContaining('quedó confirmada'), findsOneWidget);
  });

  group('API mode', () {
    late List<String> calls;
    late int checkoutStatus;
    Uri? opened;

    Future<void> bookAndOpenPortal(WidgetTester tester) async {
      calls = [];
      opened = null;
      final backend = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        switch (request.url.path) {
          case '/api/v1/auth/login':
            return _json({'access_token': 'jwt', 'token_type': 'Bearer', 'expires_in': 900}, 200);
          case '/api/v1/me':
            return _json({'id': 'u1', 'roles': ['PACIENTE'], 'permissions': ['citas.reservar']}, 200);
          case '/api/v1/availability':
            final start = DateTime.now().toUtc().add(const Duration(days: 1)).copyWith(hour: 14, minute: 0, second: 0, millisecond: 0, microsecond: 0);
            return _json({
              'items': [
                {
                  'horario_id': 'slot-1',
                  'medico_id': 'doc-1',
                  'inicio_utc': start.toIso8601String(),
                  'fin_utc': start.add(const Duration(minutes: 30)).toIso8601String(),
                },
              ],
            }, 200);
          case '/api/v1/appointments':
            return _json({'id': 'cita-1', 'estado': 'PENDIENTE_PAGO'}, 201);
          case '/api/v1/invoices':
            return _json({'id': 'inv-1', 'estado': 'PENDIENTE', 'total': '8.00', 'moneda': 'USD'}, 201);
          case '/api/v1/payments/checkout':
            return checkoutStatus == 201
                ? _json({'pago_id': 'p-1', 'checkout_url': 'https://checkout.stripe.com/c/pay/cs_test_1'}, 201)
                : _json({'detail': 'Payment provider is not configured', 'correlation_id': 'c-9'}, checkoutStatus);
        }
        return _json({'detail': 'unexpected'}, 404);
      });
      await tester.pumpWidget(
        MedicalBookingApp(
          dependencies: AppDependencies.api(
            apiBaseUrl: 'http://api.test/api/v1',
            client: backend,
            store: MemorySessionStore(),
            services: const [MedicalService(id: serviceId, name: 'Toma de muestra', durationMin: 20, basePrice: 8)],
            openPage: (uri) => opened = uri,
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
      await tapText(tester, find.text('Nueva cita'));
      await tapText(tester, find.byType(ChoiceChip).at(1));
      await tapText(tester, find.descendant(of: find.byType(SlotPicker), matching: find.byType(OutlinedButton)).first);
      await tapText(tester, find.text('Continuar'));
      await tapText(tester, find.text('Confirmar reserva'));
    }

    testWidgets('paying invoices the appointment and sends the patient to the Stripe page', (tester) async {
      await useScreen(tester);
      checkoutStatus = 201;
      await bookAndOpenPortal(tester);

      await tapText(tester, find.text('Pagar ahora'));

      expect(opened, Uri.parse('https://checkout.stripe.com/c/pay/cs_test_1'));
      expect(calls, containsAllInOrder(['POST /api/v1/invoices', 'POST /api/v1/payments/checkout']));
    });

    testWidgets('when the provider is not available it says so in Spanish and keeps the appointment', (tester) async {
      await useScreen(tester);
      checkoutStatus = 503;
      await bookAndOpenPortal(tester);

      await tapText(tester, find.text('Pagar ahora'));

      expect(opened, isNull);
      expect(find.textContaining('El pago en línea no está disponible'), findsOneWidget);
      expect(find.textContaining('c-9'), findsOneWidget);
      expect(find.textContaining('not configured'), findsNothing);
      expect(find.text('Pagar ahora'), findsOneWidget);
    });
  });

  group('return from the payment page', () {
    Future<void> openAt(WidgetTester tester, String route) async {
      await useScreen(tester, route: route);
      await tester.pumpWidget(MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)));
      await tester.pumpAndSettle();
    }

    testWidgets('success says the payment is being confirmed, never that it is paid', (tester) async {
      await openAt(tester, '/pago/exito');

      expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
      expect(find.textContaining('pagado'), findsNothing);
    });

    testWidgets('cancelled says nothing was charged', (tester) async {
      await openAt(tester, '/pago/cancelado');

      expect(find.text('Cancelaste el pago'), findsOneWidget);
      expect(find.textContaining('No se cobró nada'), findsOneWidget);
    });
  });
}
