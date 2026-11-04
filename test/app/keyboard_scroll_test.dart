import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Desktop browsers: the page scroll is not wired to the keyboard by default there (it is on Android).
  testWidgets('the keyboard scrolls the landing page as soon as it opens', variant: TargetPlatformVariant.only(TargetPlatform.windows), (
    tester,
  ) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MedicalBookingApp(dependencies: AppDependencies.demo(latency: Duration.zero)));
    await tester.pumpAndSettle();

    double offset() => tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect(offset(), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(0));

    final afterPageDown = offset();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(afterPageDown));
  });
}
