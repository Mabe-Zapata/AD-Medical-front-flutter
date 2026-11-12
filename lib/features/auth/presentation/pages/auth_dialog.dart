import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/presentation/widgets/login_form.dart';
import 'package:medicalbooking_portal/features/auth/presentation/widgets/register_form.dart';
import 'package:medicalbooking_portal/features/auth/presentation/widgets/registration_sent.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Only same-site routes are accepted as a destination.
String safeNext(String? target) =>
    target != null && target.startsWith('/') && !target.startsWith('//') ? target : Routes.portal;

enum AuthMode { login, register }

/// Container: the sign-in / sign-up modal. It owns the state and talks to the session; the role of
/// a new account is always patient because this app is the patients' portal.
class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key, this.mode = AuthMode.login, this.next, this.expired = false});

  final AuthMode mode;

  /// Route to open after signing in.
  final String? next;

  /// The previous session ended because it expired.
  final bool expired;

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late AuthMode _mode = widget.mode;
  final _email = TextEditingController();
  final _password = TextEditingController();
  ({String email, String password})? _demo;
  bool _prefilled = false;
  bool _busy = false;
  ErrorView? _error;
  String? _emailError;
  String? _passwordError;

  /// Set once the sign-up was accepted: the person must now open the link sent by email.
  String? _registeredEmail;

  /// The last sign-in failed with wrong credentials: maybe the account is not activated yet.
  bool _activationHint = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The demo account is prefilled once; the context cannot be read from initState.
    if (_prefilled) return;
    _prefilled = true;
    _demo = AppScope.of(context).demoCredentials;
    _email.text = _demo?.email ?? '';
    _password.text = _demo?.password ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchTo(AuthMode mode) => setState(() {
    _mode = mode;
    _error = null;
    _emailError = null;
    _passwordError = null;
    _activationHint = false;
  });

  /// After a sign-up the person goes back to sign in, with the email already typed.
  void _goToLogin() {
    final email = _registeredEmail;
    setState(() {
      _registeredEmail = null;
      if (email != null) _email.text = email;
      if (_demo == null) _password.clear();
    });
    _switchTo(AuthMode.login);
  }

  void _signIn() {
    final email = _email.text.trim();
    final emailError = email.isEmpty
        ? 'Escribe tu correo electrónico.'
        : (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? null : 'Escribe un correo válido.');
    final passwordError = _password.text.isEmpty ? 'Escribe tu contraseña.' : null;
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _error = null;
      });
      return;
    }
    final session = AppScope.of(context).session;
    final navigator = Navigator.of(context);
    _run(() async {
      await session.signIn(_email.text, _password.text);
      if (mounted) navigator.pushReplacementNamed(safeNext(widget.next));
    });
  }

  void _register(NewPatientAccount account) {
    final session = AppScope.of(context).session;
    _run(() async {
      final sent = await session.register(account);
      if (mounted) setState(() => _registeredEmail = sent.email);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _activationHint = false;
    });
    try {
      await action();
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(error);
          _activationHint = error is AppError && error.kind == ErrorKind.invalidCredentials;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _registeredEmail != null;
    final login = _mode == AuthMode.login;
    return TwoPanelModal(
      tag: 'Portal del paciente',
      headline: sent
          ? 'Casi listo: activa tu cuenta.'
          : (login ? 'Tus citas y resultados, en un solo lugar.' : 'Crea tu cuenta de paciente.'),
      bullets: const [
        'Reserva tu cita de laboratorio en minutos.',
        'Consulta tus resultados validados cuando estén listos.',
        'Tus datos clínicos viajan protegidos y solo tú los ves.',
      ],
      footerLabel: login ? 'Acceso de pacientes' : 'Cuenta de paciente',
      footerNote: login ? 'Sesión segura' : 'Registro gratuito',
      centered: true,
      child: sent
          ? RegistrationSent(email: _registeredEmail!, onLogin: _goToLogin)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(login ? 'Bienvenido' : 'Nueva cuenta', color: Tokens.blueText),
                const SizedBox(height: 8),
                Text(
                  login ? 'Iniciar sesión' : 'Crear cuenta',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
                ),
                const SizedBox(height: 20),
                if (login)
                  LoginForm(
                    email: _email,
                    password: _password,
                    busy: _busy,
                    error: _error,
                    emailError: _emailError,
                    passwordError: _passwordError,
                    onEdited: () => setState(() {
                      _emailError = null;
                      _passwordError = null;
                    }),
                    expired: widget.expired,
                    activationHint: _activationHint,
                    demoHint: _demo == null ? null : 'Cuenta demo: ${_demo!.email} / ${_demo!.password}.',
                    onSubmit: _signIn,
                    onRegister: () => _switchTo(AuthMode.register),
                  )
                else
                  RegisterForm(
                    busy: _busy,
                    error: _error,
                    onSubmit: _register,
                    onLogin: () => _switchTo(AuthMode.login),
                  ),
              ],
            ),
    );
  }
}
