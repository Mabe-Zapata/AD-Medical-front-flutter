import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_saved_card_repository.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/presentation/pages/save_card_dialog.dart';

void main() {
  test('starting a card setup sends an idempotency key and maps the client secret and public key', () async {
    http.Request? sent;
    final repository = HttpSavedCardRepository(
      ApiClient(
        baseUrl: 'http://api.test/api/v1',
        token: () => 'jwt',
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({'client_secret': 'seti_1_secret_x', 'publishable_key': 'pk_test_x'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final setup = await repository.startSetup('u1');

    expect(sent!.method, 'POST');
    expect(sent!.url.path, '/api/v1/me/payment-methods/setup-intents');
    expect(sent!.headers['Idempotency-Key'], isNotEmpty);
    expect(setup.clientSecret, 'seti_1_secret_x');
    expect(setup.publishableKey, 'pk_test_x');
  });

  testWidgets('saving a card needs the consent box, and outside the browser it says nothing was saved', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaveCardDialog(
            start: () async => const CardSetup(clientSecret: 'seti_1_secret_x', publishableKey: 'pk_test_x'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Autorizo guardar esta tarjeta'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
    expect(find.textContaining('No se guardó nada'), findsOneWidget);
    final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar tarjeta'));
    expect(save.onPressed, isNull);
  });
}
