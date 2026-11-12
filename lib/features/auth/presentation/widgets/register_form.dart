import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';
import 'package:medicalbooking_portal/features/auth/presentation/widgets/registration_messages.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/strength_bar.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/password_field.dart';

const _gap = 14.0;

/// Fields of the sign-up modal. It keeps its own field state and validation messages; the container
/// only receives a complete [NewPatientAccount] through [onSubmit] and reports [busy] and [error].
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.busy, required this.error, required this.onSubmit, required this.onLogin});

  final bool busy;
  final ErrorView? error;
  final void Function(NewPatientAccount account) onSubmit;
  final VoidCallback onLogin;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _terms = false;
  bool _dataUse = false;
  bool _submitted = false;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _email, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  NewPatientAccount _account() {
    return NewPatientAccount(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      password: _password.text,
    ).normalized();
  }

  Set<RegistrationProblem> get _problems => registrationProblems(_account()).toSet();

  String? _error(RegistrationProblem problem) =>
      _submitted && _problems.contains(problem) ? registrationMessage(problem) : null;

  bool get _mismatch => _confirm.text.isNotEmpty && _confirm.text != _password.text;

  void _submit() {
    setState(() => _submitted = true);
    if (_problems.isEmpty && !_mismatch && _confirm.text.isNotEmpty && _terms && _dataUse) widget.onSubmit(_account());
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Two columns when each field keeps a readable width; one field per row on narrow phones.
      final columns = constraints.maxWidth >= 400;
      Widget pair(Widget a, Widget b) => columns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
            )
          : Column(children: [a, const SizedBox(height: _gap), b]);
      final match = _confirm.text.isNotEmpty && !_mismatch;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pair(
            TextField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Nombres', errorText: _error(RegistrationProblem.firstName)),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Apellidos', errorText: _error(RegistrationProblem.lastName)),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: _gap),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.mail_outline, size: 20),
              errorText: _error(RegistrationProblem.email),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Tokens.blueTint, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline, size: 16, color: Tokens.blue),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Te enviaremos un enlace para activar tu cuenta y, después, las notificaciones de tus citas y resultados.',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: Tokens.blueText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          pair(
            PasswordField(
              controller: _password,
              label: 'Contraseña',
              errorText: _error(RegistrationProblem.passwordLength),
              onChanged: (_) => setState(() {}),
            ),
            PasswordField(
              controller: _confirm,
              label: 'Confirmar',
              errorText: _mismatch
                  ? 'Las contraseñas no coinciden.'
                  : (_submitted && _confirm.text.isEmpty ? 'Repite la contraseña.' : null),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 10),
          StrengthBar(level: passwordStrength(_password.text)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mínimo $minPasswordLength caracteres. Mezcla mayúsculas, números y símbolos.',
                  style: const TextStyle(fontSize: 12, color: Tokens.muted, height: 1.4),
                ),
              ),
              if (match) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, size: 16, color: Tokens.success),
              ],
            ],
          ),
          const SizedBox(height: _gap),
          _Consent(
            value: _terms,
            error: _submitted && !_terms ? 'Debes aceptar los términos para crear la cuenta.' : null,
            onChanged: (value) => setState(() => _terms = value),
            text: 'Acepto los términos de servicio y la política de privacidad de Medilo.',
          ),
          _Consent(
            value: _dataUse,
            onChanged: (value) => setState(() => _dataUse = value),
            text:
                'Autorizo el uso de mis datos personales y de salud para gestionar mis citas y resultados, '
                'y para enviarme notificaciones.',
          ),
          if (widget.error != null) ...[const SizedBox(height: _gap), ErrorBanner(error: widget.error!)],
          const SizedBox(height: _gap),
          SizedBox(
            width: double.infinity,
            // Stays disabled until the person confirms how their data will be used.
            child: FilledButton(
              onPressed: widget.busy || !_dataUse ? null : _submit,
              child: widget.busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Crear cuenta'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('¿Ya tienes cuenta? ', style: TextStyle(color: Tokens.muted)),
                TextButton(onPressed: widget.busy ? null : widget.onLogin, child: const Text('Inicia sesión')),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _Consent extends StatelessWidget {
  const _Consent({required this.value, required this.onChanged, required this.text, this.error});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CheckboxListTile(
        value: value,
        onChanged: (checked) => onChanged(checked ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: VisualDensity.compact,
        activeColor: Tokens.blue,
        title: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4)),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(error!, style: const TextStyle(color: Tokens.danger, fontSize: 12)),
        ),
    ],
  );
}
