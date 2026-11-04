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
    final uri = Uri.parse(settings.name ?? Routes.home);
    final name = uri.path;
    final argument = settings.arguments is String ? settings.arguments as String : null;

    if (_protected.contains(name) && !_dependencies.session.isSignedIn) {
      return _route(const RouteSettings(name: Routes.login), LoginPage(next: name));
    }

    final Widget page = switch (name) {
      Routes.login => LoginPage(next: argument, expired: uri.queryParameters['motivo'] == 'expirada'),
      Routes.book => BookingPage(serviceId: argument),
      Routes.portal => PortalPage(justBookedId: argument),
      _ => const LandingPage(),
    };
    return _route(settings, page);
  }

  /// Flutter web only scrolls with the keyboard (arrows, Page Up/Down, Space) when something inside the
  /// route has focus; without it every key press is dropped. The autofocus node makes it work on arrival.
  static Route<dynamic> _route(RouteSettings settings, Widget page) =>
      MaterialPageRoute(settings: settings, builder: (_) => Focus(autofocus: true, child: page));
}
