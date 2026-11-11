import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/demo_payment_repository.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_payment_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  const stripe = 'https://checkout.stripe.com/c/pay/cs_test_1';

  group('HttpPaymentRepository', () {
    late List<http.Request> sent;
    var checkoutUrl = stripe;

    HttpPaymentRepository repository() {
      sent = [];
      checkoutUrl = stripe;
      final api = ApiClient(
        client: MockClient((request) async {
          sent.add(request);
          return switch (request.url.path) {
            '/api/v1/invoices' => _json({'id': 'inv-1', 'estado': 'PENDIENTE', 'total': '8.00', 'moneda': 'USD'}, 201),
            '/api/v1/payments/checkout' => _json({'pago_id': 'p-1', 'checkout_url': checkoutUrl}, 201),
            _ => _json({'detail': 'unexpected'}, 404),
          };
        }),
        baseUrl: 'http://api.test/api/v1',
        token: () => 'jwt',
      );
      return HttpPaymentRepository(api);
    }

    test('invoices the appointment, then opens the checkout of that invoice', () async {
      final page = await repository().startCheckout(patientId: 'u1', appointmentId: 'cita-1');

      expect(page, Uri.parse(stripe));
      expect(sent.map((r) => '${r.method} ${r.url.path}'), ['POST /api/v1/invoices', 'POST /api/v1/payments/checkout']);
      expect(jsonDecode(sent[0].body), {'cita_id': 'cita-1'});
      expect(jsonDecode(sent[1].body), {'factura_id': 'inv-1'});
      expect(sent[1].headers['Idempotency-Key'], isNotNull);
    });

    test('a second attempt reuses the invoice and the idempotency key', () async {
      final repo = repository();
      await repo.startCheckout(patientId: 'u1', appointmentId: 'cita-1');
      await repo.startCheckout(patientId: 'u1', appointmentId: 'cita-1');

      expect(sent.where((r) => r.url.path == '/api/v1/invoices'), hasLength(1));
      final keys = sent.where((r) => r.url.path == '/api/v1/payments/checkout').map((r) => r.headers['Idempotency-Key']);
      expect(keys.toSet(), hasLength(1));
    });

    test('never sends the patient to a page that is not https Stripe', () async {
      final repo = repository();
      for (final url in ['http://checkout.stripe.com/x', 'https://evil.example/stripe.com', 'javascript:alert(1)']) {
        checkoutUrl = url;
        await expectLater(
          repo.startCheckout(patientId: 'u1', appointmentId: 'cita-1'),
          throwsA(isA<AppError>()),
          reason: url,
        );
      }
    });
  });

  group('DemoPaymentRepository', () {
    test('confirms a pending appointment and has no page to open', () async {
      final db = DemoDatabase(latency: Duration.zero);
      final pending = Appointment(
        id: 'c1',
        patientId: 'u1',
        service: db.services.first,
        slot: db.slotAt(DateTime.now(), 9, 0),
        status: AppointmentStatus.pendingPayment,
        bookedAt: DateTime.now().toUtc(),
      );
      db.appointments.add(pending);

      expect(await DemoPaymentRepository(db).startCheckout(patientId: 'u1', appointmentId: 'c1'), isNull);
      expect(db.appointments.firstWhere((a) => a.id == 'c1').status, AppointmentStatus.confirmed);
    });

    test('refuses an appointment that is not pending or not the patient\'s', () async {
      final db = DemoDatabase(latency: Duration.zero);
      db.appointments.add(
        Appointment(
          id: 'c1',
          patientId: 'u1',
          service: db.services.first,
          slot: db.slotAt(DateTime.now(), 9, 0),
          status: AppointmentStatus.confirmed,
          bookedAt: DateTime.now().toUtc(),
        ),
      );
      final repo = DemoPaymentRepository(db);

      await expectLater(
        repo.startCheckout(patientId: 'u1', appointmentId: 'c1'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.conflict)),
      );
      await expectLater(
        repo.startCheckout(patientId: 'other', appointmentId: 'c1'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.forbidden)),
      );
    });
  });
}
