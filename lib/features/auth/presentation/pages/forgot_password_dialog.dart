import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: the patient asks for a link to create a new password. The answer is the same whether or not the
/// email has an account, so the screen never says which one it is.
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  ErrorView? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = const ErrorView('Escribe el correo de tu cuenta.'));
      return;
    }
    final deps = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await deps.passwordReset.request(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TwoPanelModal(
    tag: 'Recuperar contraseña',
    headline: 'Recupera el acceso a tu cuenta.',
    bullets: const [
      'Te enviamos un enlace al correo de tu cuenta.',
      'El enlace es de un solo uso y vence en 1 hora.',
      'Si no aparece, revisa la carpeta de spam.',
    ],
    footerLabel: 'Cuenta de paciente',
    footerNote: 'Sesión segura',
    child: _sent ? const _Sent() : _form(),
  );

  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('Acceso de pacientes'),
      const SizedBox(height: 8),
      const Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        onSubmitted: (_) => _send(),
        decoration: const InputDecoration(
          labelText: 'Correo electrónico',
          prefixIcon: Icon(Icons.mail_outline, size: 20),
        ),
      ),
      if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(error: _error!)],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: _busy ? 'Enviando…' : 'Enviar enlace', onPressed: _busy ? null : _send),
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
          child: const Text('Volver a iniciar sesión'),
        ),
      ),
    ],
  );
}

class _Sent extends StatelessWidget {
  const _Sent();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Tokens.success.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined, color: Tokens.success, size: 30),
      ),
      const SizedBox(height: 18),
      const Text(
        'Revisa tu correo',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 12),
      const Text(
        'Si la dirección tiene una cuenta, te enviamos un enlace para crear una contraseña nueva. Caduca en 1 hora.',
        style: TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(
          label: 'Volver a iniciar sesión',
          trailing: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
        ),
      ),
    ],
  );
}
