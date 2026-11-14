import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/http/idempotency_key.dart';
import 'package:medicalbooking_portal/features/payments/data/storage/payment_trail_store.dart';
import 'package:medicalbooking_portal/features/payments/data/storage/payment_trail_store_memory.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_status.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

/// Talks to POST /api/v1/invoices, POST /api/v1/payments/checkout, GET /api/v1/invoices/{id}/checkout-status and
/// POST /api/v1/payments/{id}/refunds.
///
/// The API cannot give an invoice or a payment back (no listing), so the ones this browser tab created are
/// remembered in a [PaymentTrailStore] (sessionStorage in the browser, so a reload keeps them): a second attempt
/// on the same appointment reuses the invoice and the idempotency key, which the backend answers by replaying the
/// pending checkout, or by checking with Stripe and confirming it when it was already paid. The invoice id feeds
/// the status call and the payment id feeds the refund, so both only work for a payment started in this tab.
class HttpPaymentRepository implements PaymentRepository {
  HttpPaymentRepository(this._api, {PaymentTrailStore? trail}) : _store = trail ?? MemoryPaymentTrailStore() {
    _trails.addAll(_store.load());
  }

  final ApiClient _api;
  final PaymentTrailStore _store;
  final Map<String, PaymentTrail> _trails = {};
  final Map<String, String> _refundKeys = {};

  @override
  Future<CheckoutStart> startCheckout({required String patientId, required String appointmentId}) async {
    final trail = _trails[appointmentId] ?? await _invoice(appointmentId);
    final json =
        await _api.post(
              '/payments/checkout',
              headers: {'Idempotency-Key': trail.key},
              body: {'factura_id': trail.invoiceId},
            )
            as Map<String, dynamic>;
    final paymentId = json['pago_id'];
    if (paymentId is String) _remember(appointmentId, (invoiceId: trail.invoiceId, key: trail.key, paymentId: paymentId));
    return _start(json);
  }

  Future<PaymentTrail> _invoice(String appointmentId) async {
    final json = await _api.post('/invoices', body: {'cita_id': appointmentId}) as Map<String, dynamic>;
    final trail = (invoiceId: json['id'] as String, key: newIdempotencyKey(), paymentId: null as String?);
    _remember(appointmentId, trail);
    return trail;
  }

  void _remember(String appointmentId, PaymentTrail trail) {
    _trails[appointmentId] = trail;
    _store.save(_trails);
  }

  @override
  // An invoice alone is not a payment: if the checkout failed (for example 503) nothing was started.
  bool knowsPayment(String appointmentId) => _trails[appointmentId]?.paymentId != null;

  @override
  Future<CheckoutStatus> checkoutStatus({required String patientId, required String appointmentId}) async {
    final trail = _trails[appointmentId];
    if (trail == null) throw const AppError(ErrorKind.notFound, 'no invoice known for this appointment');
    final json = await _api.get('/invoices/${trail.invoiceId}/checkout-status') as Map<String, dynamic>;
    final paymentId = json['pago_id'] as String;
    _remember(appointmentId, (invoiceId: trail.invoiceId, key: trail.key, paymentId: paymentId));
    final next = json['proximo_reintento_en'];
    return CheckoutStatus(
      paymentId: paymentId,
      state: switch (json['estado']) {
        'PENDIENTE' => CheckoutState.pending,
        'CONFIRMADO' => CheckoutState.confirmed,
        'RECHAZADO' => CheckoutState.rejected,
        'CANCELADO' => CheckoutState.cancelled,
        final other => throw AppError(ErrorKind.unknown, 'unknown checkout state $other'),
      },
      retriesDone: json['reintentos_realizados'] as int,
      retriesMax: json['reintentos_maximos'] as int,
      retriesExhausted: json['reintentos_agotados'] as bool,
      nextRetryAt: next is String ? DateTime.parse(next).toUtc() : null,
      lastErrorCode: json['ultimo_error_codigo'] as String?,
    );
  }

  @override
  Future<Refund> requestRefund({
    required String patientId,
    required String appointmentId,
    required RefundReason reason,
    String? text,
  }) async {
    final paymentId =
        _trails[appointmentId]?.paymentId ??
        (await checkoutStatus(patientId: patientId, appointmentId: appointmentId)).paymentId;
    // One key per payment and reason: a retry after a lost answer replays the same refund; another reason is
    // another request.
    final keyId = '$paymentId/${reason.code}';
    final json =
        await _api.post(
              '/payments/$paymentId/refunds',
              headers: {'Idempotency-Key': _refundKeys.putIfAbsent(keyId, newIdempotencyKey)},
              body: {
                'motivo_codigo': reason.code,
                if (text != null && text.trim().isNotEmpty) 'motivo_texto': text.trim(),
              },
            )
            as Map<String, dynamic>;
    _refundKeys.remove(keyId);
    return Refund(
      id: json['id'] as String,
      paymentId: json['pago_id'] as String,
      state: json['estado'] == 'FALLIDO' ? RefundState.failed : RefundState.pending,
      amount: json['monto'] as String,
      reason: json['motivo_codigo'] as String,
      requestedAt: DateTime.parse(json['solicitado_en'] as String).toUtc(),
    );
  }

  /// The embedded form when the API sends a `client_secret` and a `publishable_key`, otherwise the hosted page.
  CheckoutStart _start(Map<String, dynamic> json) {
    final secret = json['client_secret'];
    final key = json['publishable_key'];
    if (secret is String && secret.isNotEmpty && key is String && key.isNotEmpty) {
      return Embedded(clientSecret: secret, publishableKey: key);
    }
    return RedirectTo(_hostedPage(json['checkout_url']));
  }

  /// The patient is sent only to Stripe over https, whatever the API answers.
  Uri _hostedPage(Object? raw) {
    final uri = raw is String ? Uri.tryParse(raw) : null;
    if (uri == null || uri.scheme != 'https' || !(uri.host == 'stripe.com' || uri.host.endsWith('.stripe.com'))) {
      throw const AppError(ErrorKind.unknown, 'checkout_url is not an https Stripe page');
    }
    return uri;
  }
}
