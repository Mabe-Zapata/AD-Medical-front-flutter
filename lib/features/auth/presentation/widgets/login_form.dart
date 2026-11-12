import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/password_field.dart';

/// Presentational: fields and buttons of the sign-in modal. The container owns the state.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.email,
    required this.password,
    required this.busy,
    required this.error,
    required this.emailError,
    required this.passwordError,
    required this.onEdited,
    required this.expired,
    required this.activationHint,
    required this.demoHint,
    required this.onSubmit,
    required this.onRegister,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final ErrorView? error;

  /// Field-level messages from the container's validation; shown under the field.
  final String? emailError;
  final String? passwordError;

  /// Called when a field changes, so the container can clear stale messages.
  final VoidCallback onEdited;
  final bool expired;

  /// Shown after a failed sign-in: the account may simply not be activated yet.
  final bool activationHint;
  final String? demoHint;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (expired) ...[
        const InfoBanner(
          message: 'Tu sesión expiró. Inicia sesión de nuevo.',
          color: Tokens.warning,
          icon: Icons.schedule,
        ),
        const SizedBox(height: 16),
      ],
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => onEdited(),
        decoration: InputDecoration(
          labelText: 'Correo electrónico',
          prefixIcon: const Icon(Icons.mail_outline, size: 20),
          errorText: emailError,
        ),
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: password,
        label: 'Contraseña',
        errorText: passwordError,
        onChanged: (_) => onEdited(),
        onSubmitted: (_) => onSubmit(),
      ),
      if (error != null) ...[
        const SizedBox(height: 16),
        ErrorBanner(error: error!),
        if (activationHint)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '¿Te acabas de registrar? Activa tu cuenta con el enlace que te enviamos al correo.',
              style: TextStyle(fontSize: 12.5, color: Tokens.muted, height: 1.4),
            ),
          ),
      ],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Iniciar sesión'),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Tokens.blueTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Tokens.blueSoft),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('¿Aún no tienes cuenta?', style: TextStyle(color: Tokens.blueText)),
            ),
            TextButton(
              onPressed: busy ? null : onRegister,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      if (demoHint != null) ...[
        const SizedBox(height: 12),
        InfoBanner(message: '$demoHint Versión demo: no hay conexión con el servidor.', color: Tokens.info, icon: Icons.info_outline),
      ],
    ],
  );
}
