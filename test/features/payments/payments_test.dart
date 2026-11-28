import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/demo_payment_repository.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_payment_repository.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/payment_source.dart';
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

      expect(page, isA<RedirectTo>().having((r) => r.page, 'page', Uri.parse(stripe)));
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

    test('an answer with a client secret opens the embedded form, not a redirect', () async {
      final api = ApiClient(
        client: MockClient(
          (request) async => request.url.path == '/api/v1/invoices'
              ? _json({'id': 'inv-1'}, 201)
              : _json({'pago_id': 'p-1', 'client_secret': 'cs_test_x_secret_y', 'publishable_key': 'pk_test_z'}, 201),
        ),
        baseUrl: 'http://api.test/api/v1',
        token: () => 'jwt',
      );

      final start = await HttpPaymentRepository(api).startCheckout(patientId: 'u1', appointmentId: 'cita-1');

      expect(
        start,
        isA<Embedded>().having((e) => e.clientSecret, 'secret', 'cs_test_x_secret_y').having((e) => e.publishableKey, 'key', 'pk_test_z'),
      );
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
    late DemoDatabase db;
    late DemoPaymentRepository repo;

    setUp(() {
      db = DemoDatabase(latency: Duration.zero);
      repo = DemoPaymentRepository(db);
      db.appointments.add(
        Appointment(
          id: 'c1',
          patientId: 'u1',
          service: db.services.first,
          slot: db.slotAt(DateTime.now(), 9, 0),
          status: AppointmentStatus.pendingPayment,
          bookedAt: DateTime.now().toUtc(),
        ),
      );
    });

    AppointmentStatus status() => db.appointments.firstWhere((a) => a.id == 'c1').status;

    Future<void> pay(PaymentSource source) => repo.payWithCard(patientId: 'u1', appointmentId: 'c1', source: source);

    test('opens an embedded form and confirms only once a payment goes through, like the webhook', () async {
      expect(await repo.startCheckout(patientId: 'u1', appointmentId: 'c1'), isA<Embedded>());
      expect(status(), AppointmentStatus.pendingPayment);

      await pay(const NewCardSource('pm_card_visa'));

      expect(status(), AppointmentStatus.confirmed);
    });

    test("declines like Stripe's test cards and leaves the appointment pending", () async {
      for (final id in ['pm_card_chargeDeclined', 'pm_card_chargeDeclinedInsufficientFunds', 'pm_card_threeDSecure2Required']) {
        await expectLater(pay(NewCardSource(id)), throwsA(isA<AppError>().having((e) => e.status, 'status', 400)), reason: id);
      }
      expect(status(), AppointmentStatus.pendingPayment);
    });

    test('saves the card only when the patient asked, and a new one replaces the old', () async {
      await pay(const NewCardSource('pm_card_visa'));
      expect(db.savedCardOf('u1')!.expMonth, 9, reason: 'not asked to save: the card on file is untouched');

      final index = db.appointments.indexWhere((a) => a.id == 'c1');
      db.appointments[index] = db.appointments[index].copyWith(status: AppointmentStatus.pendingPayment);
      await pay(const NewCardSource('pm_card_visa', save: true));

      expect(db.savedCardOf('u1')!.expMonth, 12);
    });

    test('paying with the saved card needs one on file', () async {
      db.setSavedCard('u1', null);

      await expectLater(
        pay(const SavedCardSource()),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('No tienes una tarjeta guardada'))),
      );
    });

    test("refuses an appointment that is not pending or not the patient's", () async {
      await pay(const NewCardSource('pm_card_visa'));

      await expectLater(
        pay(const NewCardSource('pm_card_visa')),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.conflict)),
      );
      await expectLater(
        repo.startCheckout(patientId: 'other', appointmentId: 'c1'),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.forbidden)),
      );
    });
  });
}
