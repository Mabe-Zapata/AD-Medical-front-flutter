import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// What an alert says, so its icon and colour match the message: the same tones the banners use.
enum AlertTone {
  success(Icons.check_rounded, Tokens.success),
  info(Icons.info_outline_rounded, Tokens.blue),
  warning(Icons.priority_high_rounded, Tokens.warning),
  danger(Icons.close_rounded, Tokens.danger);

  const AlertTone(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// A SweetAlert-style popup for a notification that must be read: a centred card with a tinted icon, a title,
/// one sentence and one button. Use it for transient messages (what was just done, or what failed), never for
/// text that belongs to a field or a list, which stays inline.
Future<void> showSweetAlert(
  BuildContext context, {
  required String title,
  required String message,
  AlertTone tone = AlertTone.info,
  String actionLabel = 'Entendido',
}) => showDialog<void>(
  context: context,
  barrierDismissible: true,
  builder: (context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd + 4)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tone.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(tone.icon, size: 32, color: tone.color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tokens.slate900),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Tokens.slate600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tone.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
