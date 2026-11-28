import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_saved_card_repository.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

HttpSavedCardRepository _repo(List<Map<String, Object?>> cards, List<http.Request> sent) => HttpSavedCardRepository(
  ApiClient(
    baseUrl: 'http://api.test/api/v1',
    token: () => 'jwt',
    client: MockClient((request) async {
      sent.add(request);
      if (request.method == 'DELETE') return http.Response('', 204);
      return _json({'items': cards}, 200);
    }),
  ),
);

void main() {
  test('no cards is no saved card', () async {
    expect(await _repo(const [], []).defaultCard('u1'), isNull);
  });

  test('picks the default card and maps it without any number', () async {
    final card = await _repo([
      {'id': 'pm_a', 'brand': 'mastercard', 'last4': '4444', 'exp_month': 1, 'exp_year': 2030, 'is_default': false},
      {'id': 'pm_b', 'brand': 'visa', 'last4': '4242', 'exp_month': 9, 'exp_year': 2028, 'is_default': true},
    ], []).defaultCard('u1');

    expect(card!.id, 'pm_b');
    expect(card.brand, 'VISA');
    expect(card.last4, '4242');
    expect(card.expiry, '09/28');
  });

  test('without a default, the first card is used, and a missing expiry stays unknown', () async {
    final card = await _repo([
      {'id': 'pm_a', 'brand': 'visa', 'last4': '4242', 'exp_month': null, 'exp_year': null, 'is_default': false},
    ], []).defaultCard('u1');

    expect(card!.id, 'pm_a');
    expect(card.expiry, '--/--');
  });

  test('removing deletes that card of the caller and nothing else', () async {
    final sent = <http.Request>[];
    await _repo([
      {'id': 'pm_b', 'brand': 'visa', 'last4': '4242', 'exp_month': 9, 'exp_year': 2028, 'is_default': true},
    ], sent).remove('u1');

    final deletes = sent.where((r) => r.method == 'DELETE').toList();
    expect(deletes, hasLength(1));
    expect(deletes.single.url.path, '/api/v1/me/payment-methods/pm_b');
    expect(deletes.single.headers['Authorization'], 'Bearer jwt');
  });

  test('removing with no card on file deletes nothing', () async {
    final sent = <http.Request>[];
    await _repo(const [], sent).remove('u1');

    expect(sent.where((r) => r.method == 'DELETE'), isEmpty);
  });
}
