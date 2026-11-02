import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// Orange gradient pill used for the main calls to action.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.trailing});

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Tokens.brandGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: enabled
              ? [BoxShadow(color: Tokens.orange.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    Icon(trailing, color: Colors.white, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
