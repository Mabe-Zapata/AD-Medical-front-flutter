import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// One continuous background for the whole landing: it runs from warm to cool as the page scrolls, and the same
/// soft orange and blue shapes of the hero keep appearing down the page, so the sections read as a single page.
class PageBackdrop extends StatelessWidget {
  const PageBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Tokens.orangeTint, Colors.white, Color(0xFFF4F8FD), Color(0xFFE8EFFA)],
        stops: [0, 0.24, 0.58, 1],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          _circle(right: -180, top: 980, size: 420, color: const Color(0xFFFFD9B8), alpha: 0.45),
          _circle(left: -200, top: 1500, size: 460, color: Tokens.blueSoft, alpha: 0.7),
          _circle(right: -140, top: 2080, size: 380, color: Tokens.orangeSoft, alpha: 0.5),
          _circle(left: box.maxWidth * 0.05, top: 700, size: 12, color: Tokens.orangeLight),
          _circle(right: box.maxWidth * 0.07, top: 1000, size: 14, color: Tokens.orangeLight),
          _circle(left: box.maxWidth * 0.08, top: 1780, size: 14, color: Tokens.orangeLight),
          _circle(right: box.maxWidth * 0.12, top: 2300, size: 12, color: Tokens.orangeLight),
          child,
        ],
      ),
    ),
  );

  Widget _circle({
    double? left,
    double? right,
    required double top,
    required double size,
    required Color color,
    double alpha = 1,
  }) => Positioned(
    left: left,
    right: right,
    top: top,
    child: IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: alpha), shape: BoxShape.circle),
      ),
    ),
  );
}
