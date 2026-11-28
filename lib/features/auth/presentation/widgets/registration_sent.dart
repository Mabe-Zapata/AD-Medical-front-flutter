import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';

/// Presentational: what the person sees after signing up. The account is inactive until the link in
/// the email is opened, so there is no automatic sign-in.
class RegistrationSent extends StatelessWidget {
  const RegistrationSent({super.key, required this.email, required this.onLogin});

  final String email;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: Tokens.orangeTint, shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined, color: Tokens.orange, size: 28),
      ),
      const SizedBox(height: 18),
      const Text(
        'Revisa tu correo',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Te enviamos un enlace de activación a '),
            TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w800, color: Tokens.slate900)),
            const TextSpan(text: '. Ábrelo para activar tu cuenta: vence en 24 horas y solo sirve una vez.'),
          ],
        ),
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 12),
      const Text(
        'Si no lo ves en unos minutos, revisa la carpeta de correo no deseado. '
        'Hasta activarla no podrás iniciar sesión.',
        style: TextStyle(fontSize: 13, color: Tokens.muted, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: 'Ir a iniciar sesión', trailing: Icons.arrow_forward, onPressed: onLogin),
      ),
    ],
  );
}
