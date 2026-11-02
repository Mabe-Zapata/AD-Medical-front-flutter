import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/features/auth/presentation/pages/login_page.dart';
import 'package:medicalbooking_portal/features/booking/presentation/pages/booking_page.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/pages/landing_page.dart';
import 'package:medicalbooking_portal/features/portal/presentation/pages/portal_page.dart';

class AppRouter {
  const AppRouter(this._dependencies);

  /// Pages that need a signed-in patient.
  static const _protected = {Routes.book, Routes.portal};

  final AppDependencies _dependencies;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = Uri.parse(settings.name ?? Routes.home).path;
    final argument = settings.arguments is String ? settings.arguments as String : null;

    if (_protected.contains(name) && !_dependencies.session.isSignedIn) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: Routes.login),
        builder: (_) => LoginPage(next: name),
      );
    }

    final Widget page = switch (name) {
      Routes.login => LoginPage(next: argument),
      Routes.book => BookingPage(serviceId: argument),
      Routes.portal => PortalPage(justBookedId: argument),
      _ => const LandingPage(),
    };
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
