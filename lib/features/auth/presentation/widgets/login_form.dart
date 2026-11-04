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
    required this.expired,
    required this.demoHint,
    required this.onSubmit,
    required this.onRegister,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final ErrorView? error;
  final bool expired;
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
        decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline, size: 20)),
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: password,
        label: 'Contraseña',
        onSubmitted: (_) => onSubmit(),
      ),
      if (error != null) ...[const SizedBox(height: 16), ErrorBanner(error: error!)],
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
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('¿Aún no tienes cuenta? ', style: TextStyle(color: Tokens.muted)),
          TextButton(onPressed: busy ? null : onRegister, child: const Text('Crear cuenta')),
        ],
      ),
      if (demoHint != null) ...[
        const SizedBox(height: 12),
        InfoBanner(message: '$demoHint Versión demo: no hay conexión con el servidor.', color: Tokens.info, icon: Icons.info_outline),
      ],
    ],
  );
}
