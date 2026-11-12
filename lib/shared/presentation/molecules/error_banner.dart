import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';

/// An [ErrorView] as a red banner, with an optional "Reintentar" so the person can recover in one step.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error, this.onRetry});

  final ErrorView error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InfoBanner(
        message: error.message,
        color: Tokens.danger,
        icon: Icons.error_outline,
      ),
      if (onRetry != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ),
    ],
  );
}
