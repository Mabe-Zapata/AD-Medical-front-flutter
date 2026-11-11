import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/features/auth/presentation/pages/auth_dialog.dart';
import 'package:medicalbooking_portal/features/auth/presentation/pages/session_expired_dialog.dart';
import 'package:medicalbooking_portal/features/auth/presentation/pages/verify_email_dialog.dart';
import 'package:medicalbooking_portal/features/booking/presentation/pages/booking_dialog.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/pages/landing_page.dart';
import 'package:medicalbooking_portal/features/payments/presentation/pages/payment_result_dialog.dart';
import 'package:medicalbooking_portal/features/portal/presentation/pages/portal_page.dart';
import 'package:medicalbooking_portal/features/profile/presentation/pages/profile_dialog.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/modal_route.dart';

class AppRouter {
  const AppRouter(this._dependencies);

  /// Pages that need a signed-in patient.
  static const _protected = {Routes.book, Routes.portal, Routes.profile};

  final AppDependencies _dependencies;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? Routes.home);
    final name = uri.path;
    final argument = settings.arguments is String ? settings.arguments as String : null;

    if (_protected.contains(name) && !_dependencies.session.isSignedIn) {
      return _modal(const RouteSettings(name: Routes.login), AuthDialog(next: name));
    }

    return switch (name) {
      Routes.login => _modal(
        settings,
        AuthDialog(
          next: argument,
          expired: uri.queryParameters['motivo'] == 'expirada',
          mode: uri.queryParameters['modo'] == 'registro' ? AuthMode.register : AuthMode.login,
        ),
      ),
      Routes.register => _modal(settings, AuthDialog(next: argument, mode: AuthMode.register)),
      Routes.verify => _modal(settings, VerifyEmailDialog(token: uri.queryParameters['token'])),
      Routes.book => _modal(settings, BookingDialog(serviceId: argument)),
      Routes.sessionExpired => _modal(settings, const SessionExpiredDialog()),
      Routes.profile => _modal(settings, const ProfileDialog()),
      Routes.portal => _page(settings, PortalPage(justBookedId: argument)),
      Routes.paymentDone => _modal(settings, const PaymentResultDialog(completed: true)),
      Routes.paymentCancelled => _modal(settings, const PaymentResultDialog(completed: false)),
      _ => _page(settings, const LandingPage()),
    };
  }

  /// What the app shows when it opens. The link of the activation email (`#/verificar?token=...`) opens
  /// the verification modal over the landing page, and the payment provider's return addresses
  /// (`/pago/exito`, `/pago/cancelado`, plain paths) open the payment result; any other address opens
  /// the landing page.
  List<Route<dynamic>> initialRoutes(String initialRoute) {
    final home = onGenerateRoute(const RouteSettings(name: Routes.home));
    final path = Uri.tryParse(initialRoute)?.path;
    if (path == Routes.verify) return [home, onGenerateRoute(RouteSettings(name: initialRoute))];
    final returned = const {Routes.paymentDone, Routes.paymentCancelled}.contains(path) ? path : _returnPath(Uri.base.path);
    if (returned == null) return [home];
    return [home, onGenerateRoute(RouteSettings(name: returned))];
  }

  static String? _returnPath(String path) =>
      const {Routes.paymentDone, Routes.paymentCancelled}.where(path.endsWith).firstOrNull;

  /// Flutter web only scrolls with the keyboard (arrows, Page Up/Down, Space) when something inside the
  /// route has focus; without it every key press is dropped. The autofocus node makes it work on arrival.
  static Route<dynamic> _page(RouteSettings settings, Widget page) =>
      MaterialPageRoute(settings: settings, builder: (_) => Focus(autofocus: true, child: page));

  /// Sign-in, sign-up and booking are modals over the page the patient came from.
  static Route<dynamic> _modal(RouteSettings settings, Widget dialog) =>
      modalRoute(settings: settings, builder: (_) => dialog);
}
