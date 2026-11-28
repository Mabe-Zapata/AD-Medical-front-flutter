import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Shown over the portal's home page when the session ends on its own (the token lapsed, or the API
/// rejected it). The patient lands on the home page and chooses to sign in again.
class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({super.key});

  @override
  Widget build(BuildContext context) => TwoPanelModal(
    tag: 'Sesión cerrada',
    headline: 'Cerramos tu sesión para proteger tus datos.',
    bullets: const [
      'Por seguridad, la sesión dura 15 minutos.',
      'No se perdió nada: tus citas y resultados siguen en tu cuenta.',
      'Vuelve a iniciar sesión cuando quieras.',
    ],
    footerLabel: 'Sesión segura',
    footerNote: '15 min',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: Tokens.warning.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.timer_off_outlined, color: Tokens.warning, size: 28),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tu sesión se cerró',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 12),
        const Text(
          'Se cumplió el tiempo de la sesión y por seguridad la cerramos. Inicia sesión de nuevo para continuar.',
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Ir al inicio'),
          ),
        ),
      ],
    ),
  );
}
