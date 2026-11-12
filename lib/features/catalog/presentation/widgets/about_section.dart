import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/steps_band.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

/// "Nosotros" has no band of its own: it sits on the page background, so it flows out of the hero and steps.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.branches});

  final List<Branch> branches;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    const text = _AboutText();
    final cards = Column(
      children: [
        const _InfoCard(
          icon: Icons.schedule,
          color: Tokens.blue,
          child: Text(
            'Abierto todos los días, 08:00 – 17:00',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Tokens.blueDeep, height: 1.4),
          ),
        ),
        for (final branch in branches) ...[
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.location_on_outlined,
            color: Tokens.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Tokens.slate900)),
                const SizedBox(height: 2),
                Text(branch.address, style: const TextStyle(color: Tokens.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
    return Constrained(
      child: Padding(
        // The steps card rides up over the hero, so the gap above is shorter by that overlap.
        padding: const EdgeInsets.only(top: 104 - stepsOverlap, bottom: 72),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [const Expanded(child: text), const SizedBox(width: 56), Expanded(child: cards)],
              )
            : Column(children: [text, const SizedBox(height: 32), cards]),
      ),
    );
  }
}

class _AboutText extends StatelessWidget {
  const _AboutText();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel('Nosotros'),
      SizedBox(height: 12),
      Text(
        'Un laboratorio clínico que se adapta a tu día.',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, color: Tokens.slate900),
      ),
      SizedBox(height: 20),
      Text(
        'Elige un servicio, escoge un horario libre y llega cuando te convenga. Seguimos tus '
        'muestras desde la toma hasta la validación, y cada paciente solo ve sus propios resultados.',
        style: TextStyle(fontSize: 16, height: 1.7, color: Tokens.slate600),
      ),
      SizedBox(height: 14),
      Text(
        'Tu cuenta reúne tus citas y tus resultados en un solo lugar, y la sesión se cierra '
        'sola a los 15 minutos para proteger tus datos.',
        style: TextStyle(fontSize: 16, height: 1.7, color: Tokens.slate600),
      ),
    ],
  );
}

/// White card with a soft blue shadow and a colored icon: the same card for the opening hours and each branch.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.color, required this.child});

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.1), blurRadius: 34, offset: const Offset(0, 14))],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    ),
  );
}
