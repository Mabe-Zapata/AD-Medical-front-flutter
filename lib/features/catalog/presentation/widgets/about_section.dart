import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.branches});

  final List<Branch> branches;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    const text = _AboutText();
    final cards = Column(
      children: [for (final branch in branches) ...[_BranchCard(branch), const SizedBox(height: 14)]],
    );
    return Constrained(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 72),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
      SizedBox(height: 20),
      Row(
        children: [
          Icon(Icons.schedule, size: 18, color: Tokens.orange),
          SizedBox(width: 8),
          Flexible(
            child: Text('Abierto todos los días, 08:00 – 17:00', style: TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate700)),
          ),
        ],
      ),
    ],
  );
}

class _BranchCard extends StatelessWidget {
  const _BranchCard(this.branch);

  final Branch branch;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(gradient: Tokens.brandGradient, borderRadius: BorderRadius.circular(Tokens.radiusSm + 4)),
          child: const Icon(Icons.location_on_outlined, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
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
    ),
  );
}
