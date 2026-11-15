import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/http/idempotency_key.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';

/// Talks to GET and DELETE /api/v1/me/payment-methods. The server reads the cards from Stripe on every call
/// and never stores card data; a card is saved by the payment form, not by this repository.
class HttpSavedCardRepository implements SavedCardRepository {
  HttpSavedCardRepository(this._api);

  final ApiClient _api;

  @override
  Future<SavedCard?> defaultCard(String patientId) async {
    final json = await _api.get('/me/payment-methods') as Map<String, dynamic>;
    final cards = [for (final item in json['items'] as List) item as Map<String, dynamic>];
    if (cards.isEmpty) return null;
    final chosen = cards.firstWhere((c) => c['is_default'] == true, orElse: () => cards.first);
    return SavedCard(
      id: chosen['id'] as String,
      brand: (chosen['brand'] as String).toUpperCase(),
      last4: chosen['last4'] as String,
      expMonth: chosen['exp_month'] as int?,
      expYear: chosen['exp_year'] as int?,
    );
  }

  /// `POST /me/payment-methods/setup-intents`: a SetupIntent for off-session use. Its client secret and the public
  /// key go to the browser, which confirms the card with Stripe; nothing is stored here.
  @override
  Future<CardSetup> startSetup(String patientId) async {
    final json =
        await _api.post(
              '/me/payment-methods/setup-intents',
              headers: {'Idempotency-Key': newIdempotencyKey()},
            )
            as Map<String, dynamic>;
    return CardSetup(
      clientSecret: json['client_secret'] as String,
      publishableKey: json['publishable_key'] as String,
    );
  }

  @override
  Future<void> remove(String patientId) async {
    final card = await defaultCard(patientId);
    if (card != null) await _api.delete('/me/payment-methods/${card.id}');
  }
}
