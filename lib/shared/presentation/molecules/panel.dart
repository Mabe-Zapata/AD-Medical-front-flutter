import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      border: Border.all(color: Tokens.orangeSoft.withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(color: Tokens.orange.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10)),
      ],
    ),
    child: child,
  );
}
