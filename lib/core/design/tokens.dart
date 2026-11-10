import 'package:flutter/material.dart';

/// Design tokens. Kept in one place so they can later be generated from a
/// shared tokens file used by both frontends.
abstract final class Tokens {
  static const orange = Color(0xFFC2410C);
  static const orangeLight = Color(0xFFFF8A3D);
  static const orangeSoft = Color(0xFFFED7AA);
  static const orangeDeep = Color(0xFF9A3412);
  static const orangeTint = Color(0xFFFFF4EA);
  static const gradientStart = Color(0xFFC2410C);
  static const gradientEnd = Color(0xFFC84A0B);

  static const ink = Color(0xFF1E2432);
  static const muted = Color(0xFF656B78);

  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);

  static const success = Color(0xFF15803D);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFB45309);
  static const info = Color(0xFF2563EB);

  static const brandGradient = LinearGradient(colors: [gradientStart, gradientEnd]);

  static const radiusSm = 8.0;
  static const radiusMd = 16.0;

  static const maxWidth = 1200.0;
  static const wideBreakpoint = 900.0;
}
