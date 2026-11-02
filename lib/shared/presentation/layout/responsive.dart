import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= Tokens.wideBreakpoint;

/// Centers [child] with a max width and the page's horizontal gutter.
class Constrained extends StatelessWidget {
  const Constrained({super.key, required this.child, this.maxWidth = Tokens.maxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child),
    ),
  );
}
