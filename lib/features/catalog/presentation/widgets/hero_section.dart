import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/steps_band.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

const _heroImage = 'assets/images/hero_family.webp';

/// Landing hero: organic blobs, copy and illustration. The [header] is drawn
/// over the blobs so the page background stays continuous.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.header, required this.onStart, required this.onSeeTests});

  final Widget header;
  final VoidCallback onStart;
  final VoidCallback onSeeTests;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final minHeight = math.max(640.0, MediaQuery.sizeOf(context).height - 40);
    // No clipping: the blobs may spill below the hero, over the sections that follow, which are transparent.
    return ClipRect(
      clipBehavior: Clip.none,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            ..._blobs(box.maxWidth),
            Constrained(
              child: Column(
                children: [
                  header,
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight - 88),
                    child: Padding(
                      // The steps card rides up over the hero's bottom edge, so the hero leaves room for it.
                      padding: const EdgeInsets.only(top: 32, bottom: 32 + stepsOverlap),
                      child: wide
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _HeroCopy(wide: true, onStart: onStart, onSeeTests: onSeeTests),
                                ),
                                const SizedBox(width: 32),
                                const Expanded(flex: 7, child: _HeroImage(height: 520)),
                              ],
                            )
                          : Column(
                              children: [
                                _HeroCopy(wide: false, onStart: onStart, onSeeTests: onSeeTests),
                                const SizedBox(height: 32),
                                const _HeroImage(height: 320),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _blobs(double width) => [
    Positioned(
      top: -120,
      left: -100,
      child: _Blob(
        width: 480,
        height: 380,
        horizontal: const [42, 58, 70, 30],
        vertical: const [45, 45, 55, 55],
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFEDDC3), Color(0xFFFFE9D6), Color(0x00FFFFFF)],
          stops: [0, 0.6, 1],
        ),
      ),
    ),
    Positioned(
      top: -80,
      right: -80,
      child: _Blob(
        width: 580,
        height: 340,
        horizontal: const [35, 65, 31, 69],
        vertical: const [57, 59, 41, 43],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFECAA5), Color(0xFFFED8BA), Color(0xFFFFF1E5)],
        ),
      ),
    ),
    Positioned(
      top: 220,
      right: 30,
      child: _Blob(
        width: 620,
        height: 600,
        horizontal: const [54, 46, 42, 58],
        vertical: const [60, 58, 42, 40],
        gradient: const RadialGradient(
          colors: [Color(0xFFFFDEB8), Color(0xFFFEE4C8), Color(0x00FFFFFF)],
          stops: [0, 0.55, 0.8],
        ),
      ),
    ),
    Positioned(
      bottom: -60,
      left: width * 0.3,
      child: _Blob(
        width: 320,
        height: 220,
        horizontal: const [60, 40, 58, 42],
        vertical: const [48, 62, 38, 52],
        color: const Color(0xFFFEDBB7).withValues(alpha: 0.7),
      ),
    ),
    Positioned(
      bottom: -100,
      right: -40,
      child: _Blob(
        width: 260,
        height: 300,
        horizontal: const [50, 50, 40, 60],
        vertical: const [60, 40, 60, 40],
        gradient: const RadialGradient(colors: [Color(0xFFFECAA1), Color(0xFFFED7B6)]),
      ),
    ),
    // Blue counterpart of the orange blobs: the lab's second brand color, on the right.
    Positioned(
      top: -90,
      right: -120,
      child: _Blob(
        width: 420,
        height: 320,
        horizontal: const [45, 55, 40, 60],
        vertical: const [55, 45, 60, 40],
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Tokens.blueSoft, Tokens.blueTint],
        ),
      ),
    ),
    Positioned(
      bottom: -80,
      right: width * 0.28,
      child: _Blob(
        width: 240,
        height: 180,
        horizontal: const [55, 45, 50, 50],
        vertical: const [50, 50, 55, 45],
        color: Tokens.blueTint,
      ),
    ),
    Positioned(top: 176, left: width * 0.48, child: _Dot(20, Tokens.orangeSoft.withValues(alpha: 0.8))),
    Positioned(top: 256, left: width * 0.48, child: _Dot(12, const Color(0xFFFDBA74).withValues(alpha: 0.6))),
    Positioned(bottom: 160, left: width * 0.36, child: _Dot(14, Tokens.orangeSoft.withValues(alpha: 0.9))),
    Positioned(top: 208, right: 96, child: _Dot(10, const Color(0xFFFDBA74).withValues(alpha: 0.7))),
  ];
}

/// Border radius written the way CSS does: horizontal radii over vertical radii,
/// in percent, for top-left, top-right, bottom-right, bottom-left.
class _Blob extends StatelessWidget {
  const _Blob({
    required this.width,
    required this.height,
    required this.horizontal,
    required this.vertical,
    this.gradient,
    this.color,
  });

  final double width;
  final double height;
  final List<double> horizontal;
  final List<double> vertical;
  final Gradient? gradient;
  final Color? color;

  Radius _radius(int i) => Radius.elliptical(width * horizontal[i] / 100, height * vertical[i] / 100);

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.only(
          topLeft: _radius(0),
          topRight: _radius(1),
          bottomRight: _radius(2),
          bottomLeft: _radius(3),
        ),
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot(this.size, this.color);

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

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.wide, required this.onStart, required this.onSeeTests});

  final bool wide;
  final VoidCallback onStart;
  final VoidCallback onSeeTests;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: wide ? 68 : 42,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -1.5,
      color: Tokens.slate900,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Tokens.blueSoft, borderRadius: BorderRadius.circular(999)),
          child: const Text(
            'TU LABORATORIO EN LÍNEA',
            style: TextStyle(color: Tokens.blueDeep, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 20),
        Text('Mantente sano', style: style),
        ShaderMask(
          shaderCallback: (rect) =>
              LinearGradient(colors: [Tokens.gradientStart, Tokens.gradientEnd]).createShader(rect),
          child: Text('y fuerte', style: style.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const Text(
            'Reserva tus citas de laboratorio en línea, sigue tus muestras y consulta tus '
            'resultados validados desde un portal seguro.',
            style: TextStyle(fontSize: 18, height: 1.6, color: Tokens.slate600),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const Text(
            'Agenda en minutos y mantén tus citas y resultados en un solo lugar, sin llamadas ni filas.',
            style: TextStyle(fontSize: 16, height: 1.6, color: Tokens.slate600),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GradientButton(label: 'Comenzar', trailing: Icons.chevron_right, onPressed: onStart),
            OutlinedButton(
              onPressed: onSeeTests,
              style: OutlinedButton.styleFrom(
                foregroundColor: Tokens.blueDeep,
                side: const BorderSide(color: Tokens.blue, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              child: const Text('Ver pruebas'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: LayoutBuilder(
      builder: (context, box) {
        final panelWidth = box.maxWidth * 0.46;
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Orange and blue panels side by side, with the family drawn over both.
            Positioned(
              left: box.maxWidth * 0.06,
              top: height * 0.1,
              bottom: 0,
              width: panelWidth,
              child: const _Panel(Tokens.orangeLight, Tokens.orange),
            ),
            Positioned(
              right: box.maxWidth * 0.06,
              top: 0,
              bottom: height * 0.1,
              width: panelWidth,
              child: const _Panel(Tokens.blue, Tokens.blueDeep),
            ),
            Positioned.fill(
              child: Image.asset(_heroImage, fit: BoxFit.contain, semanticLabel: 'Una familia junto a su médico'),
            ),
            const Positioned(top: 8, right: 0, child: _ValidatedChip()),
          ],
        );
      },
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel(this.color, this.accent);

  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: color)),
        Positioned(
          left: -50,
          bottom: -50,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.5), shape: BoxShape.circle),
          ),
        ),
      ],
    ),
  );
}

class _ValidatedChip extends StatelessWidget {
  const _ValidatedChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.2), blurRadius: 28, offset: const Offset(0, 12)),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Tokens.blueSoft,
          child: Icon(Icons.check, size: 18, color: Tokens.blueDeep),
        ),
        SizedBox(width: 10),
        Text(
          'Resultados validados',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tokens.blueDeep),
        ),
      ],
    ),
  );
}
