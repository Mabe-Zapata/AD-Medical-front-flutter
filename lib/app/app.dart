import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicalbooking_portal/app/app_router.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/theme.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
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

class MedicalBookingApp extends StatefulWidget {
  const MedicalBookingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MedicalBookingApp> createState() => _MedicalBookingAppState();
}

class _MedicalBookingAppState extends State<MedicalBookingApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _router = AppRouter(widget.dependencies);

  /// Read when the app starts: a session restored after a reload counts as signed in, so its expiry is noticed.
  bool _wasSignedIn = false;

  @override
  void initState() {
    super.initState();
    _wasSignedIn = widget.dependencies.session.patient != null;
    widget.dependencies.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.dependencies.session.removeListener(_onSessionChanged);
    // The app owns its dependencies: nothing may keep running after it is gone.
    widget.dependencies.dispose();
    super.dispose();
  }

  /// Any way a session ends on its own (token expiry, a 401 from the API) lands on the home page with a
  /// modal that explains it.
  void _onSessionChanged() {
    final session = widget.dependencies.session;
    final signedIn = session.patient != null;
    if (_wasSignedIn && !signedIn && session.endReason == EndReason.expired) {
      // Back to the first page (the landing), with the explanation on top.
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.sessionExpired, (route) => route.isFirst);
    }
    _wasSignedIn = signedIn;
  }

  @override
  Widget build(BuildContext context) => AppScope(
    dependencies: widget.dependencies,
    child: MaterialApp(
      navigatorKey: _navigatorKey,
      title: '$brandName · Portal del paciente',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      onGenerateInitialRoutes: _router.initialRoutes,
      onGenerateRoute: _router.onGenerateRoute,
    ),
  );
}
