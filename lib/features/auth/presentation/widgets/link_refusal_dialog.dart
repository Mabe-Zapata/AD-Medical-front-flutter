import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';

/// Alert for a link that cannot be used (already used, expired or invalid): white card, an icon for the reason,
/// one action.
class LinkRefusalDialog extends StatelessWidget {
  const LinkRefusalDialog({super.key, required this.reason, required this.title, required this.text});

  final String reason;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (reason) {
      'INVALID' => (Icons.link_off, Tokens.danger),
      'EXPIRED' => (Icons.schedule, Tokens.orange),
      _ => (Icons.mark_email_read_outlined, Tokens.orange),
    };
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Tokens.slate900),
              ),
              const SizedBox(height: 10),
              Text(text, style: const TextStyle(fontSize: 15, height: 1.5, color: Tokens.muted)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Entendido',
                  trailing: Icons.check,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
