import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';

/// An [ErrorView] as a red banner, with the support code when the backend sent one.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});

  final ErrorView error;

  @override
  Widget build(BuildContext context) => InfoBanner(
    message: error.supportCode == null ? error.message : '${error.message}\nCódigo de soporte: ${error.supportCode}',
    color: Tokens.danger,
    icon: Icons.error_outline,
  );
}
