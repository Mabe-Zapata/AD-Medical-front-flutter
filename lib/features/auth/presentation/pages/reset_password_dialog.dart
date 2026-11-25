import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/password_reset_policy.dart';
import 'package:medicalbooking_portal/features/auth/presentation/widgets/link_refusal_dialog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/strength_bar.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/password_field.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: opened from the link in the reset email (`#/restablecer?token=...`). It checks the link first; a
/// link already used, expired or invalid goes to the login page with the reason. Otherwise it asks for the new
/// password and spends the link on success.
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key, required this.token});

  final String? token;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Future<String>? _status;
  bool _submitted = false;
  bool _busy = false;
  bool _saved = false;
  ErrorView? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // One check per opening: the link is single use.
    _status ??= AppScope.of(context).passwordReset.status(widget.token);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (missingPasswordRules(_password.text).isNotEmpty || _confirm.text != _password.text) return;
    final deps = AppScope.of(context);
    setState(() => _busy = true);
    try {
      await deps.passwordReset.confirm(token: widget.token, password: _password.text);
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = describeError(
            error,
            overrides: const {ErrorKind.validation: 'No pudimos cambiar tu contraseña. Pide un enlace nuevo.'},
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TwoPanelModal(
    tag: 'Recuperar contraseña',
    headline: 'Crea una contraseña nueva.',
    bullets: const [
      'El enlace de tu correo es de un solo uso.',
      'Vence 1 hora después de pedirlo.',
      'Al guardarla, inicia sesión con la nueva.',
    ],
    footerLabel: 'Cuenta de paciente',
    footerNote: 'Sesión segura',
    child: FutureBuilder<String>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const _Checking();
        final status = snapshot.data ?? 'INVALID';
        if (status != 'VALID') return _Refused(reason: status);
        return _saved ? const _Saved() : _form();
      },
    ),
  );

  Widget _form() {
    final missing = missingPasswordRules(_password.text);
    final mismatch = _submitted && _confirm.text != _password.text ? 'Las contraseñas no coinciden.' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Recuperar contraseña'),
        const SizedBox(height: 8),
        const Text(
          'Nueva contraseña',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 20),
        PasswordField(
          controller: _password,
          label: 'Nueva contraseña',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        StrengthBar(level: resetStrengthLevel(_password.text)),
        if (_password.text.isNotEmpty && missing.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Te falta: ${missingPasswordText(missing)}.',
            style: const TextStyle(fontSize: 12, color: Tokens.muted, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        PasswordField(
          controller: _confirm,
          label: 'Repite la nueva contraseña',
          errorText: mismatch,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(error: _error!)],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: GradientButton(label: _busy ? 'Guardando…' : 'Guardar contraseña', onPressed: _busy ? null : _save),
        ),
      ],
    );
  }
}

class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        CircularProgressIndicator(color: Tokens.orange),
        SizedBox(height: 20),
        Text('Revisando tu enlace…', style: TextStyle(fontSize: 16, color: Tokens.muted)),
      ],
    ),
  );
}

class _Saved extends StatelessWidget {
  const _Saved();

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
        'Contraseña actualizada',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 12),
      const Text(
        'Ya puedes iniciar sesión con tu correo y tu contraseña nueva.',
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

/// The link cannot be used: the login page replaces this one and the alert says why.
class _Refused extends StatefulWidget {
  const _Refused({required this.reason});

  final String reason;

  @override
  State<_Refused> createState() => _RefusedState();
}

class _RefusedState extends State<_Refused> {
  static const _alerts = {
    'USED': ('Este enlace ya se usó', 'Si ya cambiaste tu contraseña, inicia sesión con la nueva.'),
    'EXPIRED': ('Este enlace venció', 'Los enlaces para crear una contraseña duran 1 hora. Pide uno nuevo desde "¿Olvidaste tu contraseña?".'),
    'INVALID': ('El enlace no es válido', 'Abre el enlace completo que llegó a tu correo.'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToLogin());
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacementNamed(Routes.login);
    final (title, text) = _alerts[widget.reason] ?? _alerts['INVALID']!;
    await showDialog<void>(
      context: navigator.context,
      builder: (_) => LinkRefusalDialog(reason: widget.reason, title: title, text: text),
    );
  }

  @override
  Widget build(BuildContext context) => const _Checking();
}
