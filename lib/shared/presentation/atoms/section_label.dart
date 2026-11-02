import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 20, height: 2, color: Tokens.orange),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Tokens.orange,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}
