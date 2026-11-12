import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/http/idempotency_key.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/payment_repository.dart';

/// Talks to POST /api/v1/invoices and POST /api/v1/payments/checkout.
///
/// The API cannot give an invoice back (no GET), so the ones created in this app run are remembered: a
/// second attempt on the same appointment reuses the invoice and the idempotency key, which the backend
/// answers by replaying the pending checkout instead of opening another one.
class HttpPaymentRepository implements PaymentRepository {
  HttpPaymentRepository(this._api);

  final ApiClient _api;
  final Map<String, String> _invoiceByAppointment = {};
  final Map<String, String> _keyByInvoice = {};

  @override
  Future<CheckoutStart> startCheckout({required String patientId, required String appointmentId}) async {
    final invoiceId = _invoiceByAppointment[appointmentId] ?? await _invoice(appointmentId);
    final json =
        await _api.post(
              '/payments/checkout',
              headers: {'Idempotency-Key': _keyByInvoice.putIfAbsent(invoiceId, newIdempotencyKey)},
              body: {'factura_id': invoiceId},
            )
            as Map<String, dynamic>;
    return _start(json);
  }

  Future<String> _invoice(String appointmentId) async {
    final json = await _api.post('/invoices', body: {'cita_id': appointmentId}) as Map<String, dynamic>;
    return _invoiceByAppointment[appointmentId] = json['id'] as String;
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
