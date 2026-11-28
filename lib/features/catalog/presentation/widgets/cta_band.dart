import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

/// Blue closing card: it brings back the orange shape of the hero and invites the visitor to create an account.
class CtaBand extends StatelessWidget {
  const CtaBand({super.key, required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    const copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu próxima cita, a un clic.',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2),
        ),
        SizedBox(height: 10),
        Text(
          'Regístrate, activa tu cuenta desde el correo que te enviamos y reserva en minutos. '
          'Tus citas y resultados quedan guardados en tu portal.',
          style: TextStyle(color: Tokens.blueSoft, fontSize: 16, height: 1.6),
        ),
      ],
    );
    final button = FilledButton(
      onPressed: onRegister,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Tokens.blueDeep,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      child: const Text('Registrarme'),
    );
    return Constrained(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Tokens.blue, borderRadius: BorderRadius.circular(40)),
          child: Stack(
            children: [
              // Wide: the orange shape sits at the left, so the copy leaves room for it. Narrow: it moves to the corner.
              Positioned(
                left: wide ? -80 : null,
                right: wide ? null : -100,
                top: wide ? null : -120,
                bottom: wide ? -110 : null,
                child: _Circle(wide ? 280 : 190, Tokens.orangeLight.withValues(alpha: 0.9)),
              ),
              Positioned(right: wide ? 300 : null, left: wide ? null : -60, top: -90, bottom: wide ? null : -90, child: _Circle(200, Tokens.blueDeep.withValues(alpha: 0.5))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 24, vertical: wide ? 56 : 36),
                child: wide
                    ? Row(
                        children: [
                          const SizedBox(width: 120),
                          const Expanded(child: copy),
                          const SizedBox(width: 40),
                          button,
                        ],
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 24), button]),
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
