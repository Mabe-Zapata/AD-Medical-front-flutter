import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

/// How far the blue card rides up over the bottom of the hero, so hero and content read as one page.
const stepsOverlap = 72.0;

/// Deep-blue card that explains the patient journey in three steps.
class StepsBand extends StatelessWidget {
  const StepsBand({super.key});

  static const _steps = [
    (
      icon: Icons.event_available_outlined,
      title: 'Reserva',
      text: 'Elige el servicio y un horario libre de la sede. Si no puedes asistir, cancela la cita desde tu cuenta.',
    ),
    (
      icon: Icons.science_outlined,
      title: 'Seguimiento',
      text: 'Acude a tu cita y revisa en el portal cómo avanza tu orden, de la toma de la muestra a su análisis.',
    ),
    (
      icon: Icons.verified_outlined,
      title: 'Resultados',
      text: 'Cuando el laboratorio los valida, los consultas en línea. Solo tú ves los tuyos.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final cards = [
      for (final (i, step) in _steps.indexed) _Step(number: i + 1, icon: step.icon, title: step.title, text: step.text),
    ];
    return Transform.translate(
      offset: const Offset(0, -stepsOverlap),
      child: Constrained(
        child: Container(
          decoration: BoxDecoration(
            color: Tokens.blueDeep,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.28), blurRadius: 60, offset: const Offset(0, 30))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(right: -70, top: -90, child: _Circle(240, Tokens.blue.withValues(alpha: 0.6))),
              Positioned(left: 300, bottom: -70, child: _Circle(150, Tokens.orange.withValues(alpha: 0.35))),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 36, horizontal: wide ? 12 : 20),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final card in cards) Expanded(child: card)],
                      )
                    : Column(
                        children: [
                          for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(height: 24), card],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.icon, required this.title, required this.text});

  final int number;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Tokens.blue, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Tokens.orange, shape: BoxShape.circle),
                    child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(color: Tokens.blueSoft, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.55)),
            ],
          ),
        ),
      ],
    ),
  );
}
