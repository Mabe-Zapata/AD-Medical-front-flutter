import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, required this.color, required this.icon});

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13, height: 1.4))),
      ],
    ),
  );
}
