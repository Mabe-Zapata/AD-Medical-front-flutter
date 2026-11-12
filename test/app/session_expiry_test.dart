import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'a session restored after a reload still shows the modal when it expires',
    (tester) async {
      // The Ahem test font overflows rows that fit with the real font: layout is checked in the browser.
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          original?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = original);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      // The person signed in before: the store holds a session that is still valid and ends in two seconds.
      final clock = DateTime.utc(2026, 11, 3, 12);
      final store = MemorySessionStore()
        ..save(
          Session(
            token: 'jwt',
            expiresAt: clock.add(const Duration(seconds: 2)),
            patient: const Patient(id: 'u1', email: 'paciente@demo.test'),
          ),
        );
      await tester.pumpWidget(
        MedicalBookingApp(
          dependencies: AppDependencies.api(
            apiBaseUrl: 'http://api.test/api/v1',
            client: MockClient((_) async => http.Response('{}', 404)),
            store: store,
            now: () => clock,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu sesión se cerró'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Tu sesión se cerró'), findsOneWidget);
      expect(store.load(), isNull);
    },
  );
}
