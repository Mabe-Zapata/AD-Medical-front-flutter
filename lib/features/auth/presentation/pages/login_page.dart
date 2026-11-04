import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/app/widgets/page_shell.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_footer.dart';

/// Only same-site routes are accepted as a destination.
String safeNext(String? target) =>
    target != null && target.startsWith('/') && !target.startsWith('//') ? target : Routes.portal;

/// Container: owns the form state and talks to the session.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.next, this.expired = false});

  /// Route to open after a successful sign-in.
  final String? next;

  /// The previous session ended because it expired.
  final bool expired;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final _demo = AppScope.of(context).demoCredentials;
  late final _email = TextEditingController(text: _demo?.email);
  late final _password = TextEditingController(text: _demo?.password);
  bool _busy = false;
  ErrorView? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = AppScope.of(context).session;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.signIn(_email.text, _password.text);
      if (mounted) navigator.pushReplacementNamed(safeNext(widget.next));
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageShell(
    child: SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _LoginForm(
                  email: _email,
                  password: _password,
                  busy: _busy,
                  error: _error,
                  expired: widget.expired,
                  demoHint: _demo == null ? null : 'Cuenta demo: ${_demo.email} / ${_demo.password}.',
                  onSubmit: _submit,
                ),
              ),
            ),
          ),
          SiteFooter(demo: AppScope.of(context).isDemo),
        ],
      ),
    ),
  );
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.email,
    required this.password,
    required this.busy,
    required this.error,
    required this.expired,
    required this.demoHint,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final ErrorView? error;
  final bool expired;
  final String? demoHint;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Portal del paciente'),
        const SizedBox(height: 10),
        const Text(
          'Iniciar sesión',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 24),
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
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          onSubmitted: (_) => onSubmit(),
          decoration: const InputDecoration(labelText: 'Contraseña'),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          InfoBanner(
            message: error!.supportCode == null
                ? error!.message
                : '${error!.message}\nCódigo de soporte: ${error!.supportCode}',
            color: Tokens.danger,
            icon: Icons.error_outline,
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Iniciar sesión'),
          ),
        ),
        if (demoHint != null) ...[
          const SizedBox(height: 20),
          InfoBanner(message: '$demoHint Versión demo: no hay conexión con el servidor.', color: Tokens.info, icon: Icons.info_outline),
        ],
      ],
    ),
  );
}
