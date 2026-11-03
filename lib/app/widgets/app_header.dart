import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_header.dart';

/// Container for [SiteHeader]: wires it to the session and the navigator.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.onSection});

  /// Landing page passes this to scroll to sections; elsewhere nav goes home.
  final void Function(String id)? onSection;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final navigator = Navigator.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => SiteHeader(
        signedIn: session.isSignedIn,
        onSection: onSection ?? (_) => navigator.pushNamedAndRemoveUntil(Routes.home, (route) => false),
        onSignIn: () => navigator.pushNamed(Routes.login),
        onOpenPortal: () => navigator.pushNamed(Routes.portal),
        onSignOut: () {
          session.signOut();
          navigator.pushNamedAndRemoveUntil(Routes.home, (route) => false);
        },
      ),
    );
  }
}
