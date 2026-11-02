import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicalbooking_portal/app/app_router.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/theme.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_header.dart';

/// Lets every pointer (mouse drag, touch, trackpad, stylus) scroll and keeps
/// the scrollbar visible on desktop browsers.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class MedicalBookingApp extends StatelessWidget {
  const MedicalBookingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => AppScope(
    dependencies: dependencies,
    child: MaterialApp(
      title: '$brandName · Portal del paciente',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: Routes.home,
      onGenerateRoute: AppRouter(dependencies).onGenerateRoute,
    ),
  );
}
