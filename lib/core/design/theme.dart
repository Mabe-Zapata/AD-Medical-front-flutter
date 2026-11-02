import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Tokens.orange, primary: Tokens.orange),
    scaffoldBackgroundColor: Colors.white,
  );
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Tokens.radiusSm + 4),
    borderSide: BorderSide(color: color, width: width),
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: Tokens.slate700, displayColor: Tokens.slate900),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Tokens.orange,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Tokens.orangeSoft,
        selectedForegroundColor: Tokens.orangeDeep,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border(Tokens.slate200),
      enabledBorder: border(Tokens.slate200),
      focusedBorder: border(Tokens.orange, 2),
    ),
  );
}
