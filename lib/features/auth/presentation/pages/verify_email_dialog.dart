import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: opened from the link in the activation email (`#/verificar?token=...`). It activates the
/// account once and tells the person the result; the token is never shown.
class VerifyEmailDialog extends StatefulWidget {
  const VerifyEmailDialog({super.key, required this.token});

  final String? token;

  @override
  State<VerifyEmailDialog> createState() => _VerifyEmailDialogState();
}

class _VerifyEmailDialogState extends State<VerifyEmailDialog> {
  Future<void>? _activation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // One call per opening: the token is single use.
    _activation ??= AppScope.of(context).verifyEmail(widget.token);
  }

  @override
  Widget build(BuildContext context) => TwoPanelModal(
    tag: 'Verificación de correo',
    headline: 'Activa tu cuenta de paciente.',
    bullets: const [
      'El enlace de tu correo es de un solo uso.',
      'Vence 24 horas después de tu registro.',
      'Al activarla, inicia sesión con tu correo y tu contraseña.',
    ],
    footerLabel: 'Cuenta de paciente',
    footerNote: 'Sesión segura',
    child: FutureBuilder<void>(
      future: _activation,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const _Activating();
        final error = snapshot.error;
        return error == null ? const _Activated() : _NotActivated(error: describeError(error, overrides: _overrides));
      },
    ),
  );

  static const _overrides = {
    ErrorKind.validation: 'El enlace no es válido, ya se usó o venció.',
  };
}

class _Activating extends StatelessWidget {
  const _Activating();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        CircularProgressIndicator(color: Tokens.orange),
        SizedBox(height: 20),
        Text('Activando tu cuenta…', style: TextStyle(fontSize: 16, color: Tokens.muted)),
      ],
    ),
  );
}

class _Activated extends StatelessWidget {
  const _Activated();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Tokens.success.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline, color: Tokens.success, size: 30),
      ),
      const SizedBox(height: 18),
      const Text(
        'Tu cuenta está activa',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 12),
      const Text(
        'Ya puedes iniciar sesión con tu correo y tu contraseña para reservar citas y ver tus resultados.',
        style: TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(
          label: 'Iniciar sesión',
          trailing: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
        ),
      ),
    ],
  );
}

class _NotActivated extends StatelessWidget {
  const _NotActivated({required this.error});

  final ErrorView error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Tokens.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.link_off, color: Tokens.danger, size: 28),
      ),
      const SizedBox(height: 18),
      const Text(
        'No pudimos activar tu cuenta',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 16),
      ErrorBanner(error: error),
      const SizedBox(height: 12),
      const Text(
        'Si ya activaste tu cuenta, inicia sesión. Si no, pide ayuda a soporte para recibir un enlace nuevo.',
        style: TextStyle(fontSize: 13, color: Tokens.muted, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(
          label: 'Iniciar sesión',
          trailing: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
        ),
      ),
    ],
  );
}
