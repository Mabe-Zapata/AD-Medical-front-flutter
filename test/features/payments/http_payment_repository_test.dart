import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_payment_repository.dart';
import 'package:medicalbooking_portal/features/payments/data/storage/payment_trail_store_memory.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _paymentId = '11111111-1111-4111-8111-111111111111';
const _invoiceId = '22222222-2222-4222-8222-222222222222';

({HttpPaymentRepository repo, List<http.Request> sent}) _setup({int refundStatus = 201, Object? refundBody, MemoryPaymentTrailStore? trail}) {
  final sent = <http.Request>[];
  final repo = HttpPaymentRepository(
    trail: trail,
    ApiClient(
      baseUrl: 'http://api.test/api/v1',
      token: () => 'jwt',
      client: MockClient((request) async {
        sent.add(request);
        final path = request.url.path;
        if (path.endsWith('/invoices')) return _json({'id': _invoiceId, 'estado': 'PENDIENTE'}, 201);
        if (path.endsWith('/payments/checkout')) {
          return _json({'client_secret': 'cs_x', 'publishable_key': 'pk_x', 'pago_id': _paymentId}, 201);
        }
        if (path.endsWith('/checkout-status/reconcile')) {
          // The backend asked Stripe: the payment was taken, so it is confirmed now.
          return _json({
            'pago_id': _paymentId,
            'estado': 'CONFIRMADO',
            'reintentos_realizados': 0,
            'reintentos_maximos': 5,
            'reintentos_agotados': false,
            'proximo_reintento_en': null,
            'ultimo_error_codigo': null,
          }, 200);
        }
        if (path.endsWith('/checkout-status')) {
          return _json({
            'pago_id': _paymentId,
            'estado': 'PENDIENTE',
            'reintentos_realizados': 2,
            'reintentos_maximos': 5,
            'reintentos_agotados': false,
            'proximo_reintento_en': '2026-11-14T15:00:00Z',
            'ultimo_error_codigo': 'card_declined',
          }, 200);
        }
        if (path.endsWith('/refunds')) {
          return _json(
            refundBody ??
                {
                  'id': 'r1',
                  'pago_id': _paymentId,
                  'estado': 'PENDIENTE',
                  'monto': '45.00',
                  'motivo_codigo': 'CANCELACION_PACIENTE',
                  'solicitado_en': '2026-11-14T15:00:00Z',
                },
            refundStatus,
          );
        }
        return http.Response('', 404);
      }),
    ),
  );
  return (repo: repo, sent: sent);
}

void main() {
  test('a payment is unknown until its checkout was opened in this run', () async {
    final t = _setup();
    expect(t.repo.knowsPayment('a1'), isFalse);
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    expect(t.repo.knowsPayment('a1'), isTrue);
  });

  test('the status is read from the invoice and mapped', () async {
    final t = _setup();
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    final status = await t.repo.checkoutStatus(patientId: 'p', appointmentId: 'a1');

    expect(t.sent.last.url.path, '/api/v1/invoices/$_invoiceId/checkout-status');
    expect(status.state, CheckoutState.pending);
    expect(status.retriesDone, 2);
    expect(status.retriesMax, 5);
    expect(status.retriesExhausted, isFalse);
    expect(status.nextRetryAt, DateTime.utc(2026, 11, 14, 15));
    expect(status.paymentId, _paymentId);
  });

  test('the status of an appointment with no known invoice is not found, without calling the API', () async {
    final t = _setup();
    await expectLater(
      t.repo.checkoutStatus(patientId: 'p', appointmentId: 'nope'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.notFound)),
    );
    expect(t.sent, isEmpty);
  });

  test('a refund posts the reason code with an idempotency key to the payment of that appointment', () async {
    final t = _setup();
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    final refund = await t.repo.requestRefund(
      patientId: 'p',
      appointmentId: 'a1',
      reason: RefundReason.patientCancellation,
      text: '  Ya no puedo ir  ',
    );
    final request = t.sent.last;

    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/payments/$_paymentId/refunds');
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(jsonDecode(request.body), {'motivo_codigo': 'CANCELACION_PACIENTE', 'motivo_texto': 'Ya no puedo ir'});
    expect(refund.state, RefundState.pending);
    expect(refund.amount, '45.00');
  });

  test('a blank text is not sent', () async {
    final t = _setup();
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    await t.repo.requestRefund(patientId: 'p', appointmentId: 'a1', reason: RefundReason.chargeError, text: '   ');
    expect(jsonDecode(t.sent.last.body), {'motivo_codigo': 'ERROR_DE_COBRO'});
  });

  test('a failed refund keeps its key for the retry, and another reason gets another key', () async {
    final t = _setup(refundStatus: 502, refundBody: {'type': 'about:blank', 'detail': 'provider error'});
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    Future<void> ask(RefundReason reason) async {
      try {
        await t.repo.requestRefund(patientId: 'p', appointmentId: 'a1', reason: reason);
      } on AppError {
        // expected
      }
    }

    await ask(RefundReason.patientCancellation);
    await ask(RefundReason.patientCancellation);
    await ask(RefundReason.chargeError);
    final keys = [for (final r in t.sent.where((r) => r.url.path.endsWith('/refunds'))) r.headers['Idempotency-Key']];

    expect(keys[0], keys[1]);
    expect(keys[2], isNot(keys[0]));
  });

  test('a refund that went through does not reuse its key for a later request', () async {
    final t = _setup();
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    await t.repo.requestRefund(patientId: 'p', appointmentId: 'a1', reason: RefundReason.patientCancellation);
    await t.repo.requestRefund(patientId: 'p', appointmentId: 'a1', reason: RefundReason.patientCancellation);
    final keys = [for (final r in t.sent.where((r) => r.url.path.endsWith('/refunds'))) r.headers['Idempotency-Key']];
    expect(keys[0], isNot(keys[1]));
  });

  test('a reload keeps the payment: the next repository knows it and reuses the invoice and the key', () async {
    final trail = MemoryPaymentTrailStore();
    final first = _setup(trail: trail);
    await first.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    final firstKey = first.sent.last.headers['Idempotency-Key'];

    final second = _setup(trail: trail);
    expect(second.repo.knowsPayment('a1'), isTrue);
    await second.repo.startCheckout(patientId: 'p', appointmentId: 'a1');

    expect(second.sent.where((r) => r.url.path.endsWith('/invoices')), isEmpty);
    expect(second.sent.last.headers['Idempotency-Key'], firstKey);
  });

  test('verifying a payment posts to the reconcile endpoint and maps the settled answer', () async {
    final t = _setup();
    await t.repo.startCheckout(patientId: 'p', appointmentId: 'a1');
    final status = await t.repo.reconcileCheckout(patientId: 'p', appointmentId: 'a1');
    final request = t.sent.last;

    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/invoices/$_invoiceId/checkout-status/reconcile');
    expect(status.state, CheckoutState.confirmed);
    expect(status.paymentId, _paymentId);
  });

  test('verifying an appointment with no known invoice is not found, without calling the API', () async {
    final t = _setup();
    await expectLater(
      t.repo.reconcileCheckout(patientId: 'p', appointmentId: 'nope'),
      throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.notFound)),
    );
    expect(t.sent, isEmpty);
  });

  test('a refund after a reload finds the payment without asking for the status again', () async {
    final trail = MemoryPaymentTrailStore();
    await _setup(trail: trail).repo.startCheckout(patientId: 'p', appointmentId: 'a1');

    final second = _setup(trail: trail);
    await second.repo.requestRefund(patientId: 'p', appointmentId: 'a1', reason: RefundReason.patientCancellation);

    expect(second.sent.single.url.path, '/api/v1/payments/$_paymentId/refunds');
  });
}
