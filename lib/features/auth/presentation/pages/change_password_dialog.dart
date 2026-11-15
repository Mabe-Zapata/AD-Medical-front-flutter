import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/password_change_policy.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: the signed-in patient replaces their password. The current one is proved first; a wrong one
/// keeps the session, so the patient stays where they were.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  bool _saved = false;
  ErrorView? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Set<PasswordChangeProblem> get _problems => passwordChangeProblems(
    current: _current.text,
    next: _next.text,
    confirmation: _confirm.text,
  );

  /// The first message of [messages] whose problem is present; errors show only after the first submit.
  String? _fieldError(Map<PasswordChangeProblem, String> messages) {
    if (!_submitted) return null;
    for (final entry in messages.entries) {
      if (_problems.contains(entry.key)) return entry.value;
    }
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_problems.isNotEmpty) return;
    final deps = AppScope.of(context);
    final email = deps.session.patient?.email;
    if (email == null) return;
    setState(() => _busy = true);
    try {
      await deps.changePassword.call(
        email: email,
        current: _current.text,
        next: _next.text,
        confirmation: _confirm.text,
      );
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = describeError(
            error,
            overrides: const {
              ErrorKind.forbidden: 'La contraseña actual no es correcta.',
              ErrorKind.validation: 'La nueva contraseña no cumple los requisitos. Revísala e inténtalo de nuevo.',
            },
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TwoPanelModal(
    tag: 'Mi cuenta',
    headline: 'Cambia tu contraseña sin salir de tu portal.',
    bullets: const [
      'Te pedimos la contraseña actual para confirmar que eres tú.',
      'Usa al menos $minPasswordLength caracteres, distintos a la anterior.',
      'Si la contraseña actual es incorrecta, tu sesión sigue abierta.',
    ],
    footerLabel: 'Cuenta',
    footerNote: 'Privada',
    child: _saved ? _Saved(onClose: () => Navigator.of(context).maybePop()) : _form(),
  );

  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('Mi cuenta'),
      const SizedBox(height: 8),
      const Text(
        'Cambiar contraseña',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _current,
        obscureText: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Contraseña actual',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          errorText: _fieldError({PasswordChangeProblem.currentMissing: 'Escribe tu contraseña actual.'}),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _next,
        obscureText: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Nueva contraseña',
          prefixIcon: const Icon(Icons.lock_reset, size: 20),
          helperText: 'Mínimo $minPasswordLength caracteres.',
          errorText: _fieldError({
            PasswordChangeProblem.newTooShort: 'Usa al menos $minPasswordLength caracteres.',
            PasswordChangeProblem.newSameAsCurrent: 'Debe ser distinta de la actual.',
          }),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _confirm,
        obscureText: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Repite la nueva contraseña',
          prefixIcon: const Icon(Icons.check, size: 20),
          errorText: _fieldError({PasswordChangeProblem.confirmationMismatch: 'Las contraseñas no coinciden.'}),
        ),
      ),
      if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(error: _error!)],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: _busy ? 'Guardando…' : 'Cambiar contraseña', onPressed: _busy ? null : _save),
      ),
    ],
  );
}

class _Saved extends StatelessWidget {
  const _Saved({required this.onClose});

  final VoidCallback onClose;

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
        'Desde tu próximo inicio de sesión usa la nueva contraseña.',
        style: TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: 'Listo', trailing: Icons.arrow_forward, onPressed: onClose),
      ),
    ],
  );
}
