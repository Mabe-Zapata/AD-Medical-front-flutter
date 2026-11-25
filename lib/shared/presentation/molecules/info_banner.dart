import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final Color color;
  final IconData icon;

  /// When set, a close button is shown.
  final VoidCallback? onDismiss;

  /// When both are set, a text button is shown after the message.
  final String? actionLabel;
  final VoidCallback? onAction;

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
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
        if (onDismiss != null) ...[
          const SizedBox(width: 6),
          InkResponse(
            onTap: onDismiss,
            radius: 18,
            child: Tooltip(message: 'Cerrar', child: Icon(Icons.close, color: color, size: 18)),
          ),
        ],
      ],
    ),
  );
}
