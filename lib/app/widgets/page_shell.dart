import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/widgets/app_header.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

/// Header + body for the inner pages (booking, portal, login).
class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const Constrained(child: AppHeader()),
        Expanded(child: child),
      ],
    ),
  );
}
