import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Nord — an Arctic, north-bluish color palette.
/// Colors sourced from the official Nord palette (nordtheme.com).
class NordPreset extends AppThemePreset {
  @override
  String get id => 'nord';

  @override
  String get name => 'Nord';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF5E81AC),       // Nord10 — frost blue
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD8DEE9), // Nord4
        onPrimaryContainer: Color(0xFF2E3440), // Nord0
        secondary: Color(0xFF88C0D0),     // Nord8 — frost cyan
        onSecondary: Color(0xFF2E3440),
        surface: Color(0xFFECEFF4),        // Nord6 — snow white
        onSurface: Color(0xFF2E3440),      // Nord0
        surfaceContainerHighest: Color(0xFFE5E9F0), // Nord5
        onSurfaceVariant: Color(0xFF4C566A), // Nord3
        outline: Color(0xFFD8DEE9),        // Nord4
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFF88C0D0),       // Nord8 — frost cyan
        onPrimary: Color(0xFF2E3440),
        primaryContainer: Color(0xFF3B4252),
        onPrimaryContainer: Color(0xFF88C0D0),
        secondary: Color(0xFF81A1C1),     // Nord9
        onSecondary: Color(0xFF2E3440),
        surface: Color(0xFF2E3440),        // Nord0 — polar night
        onSurface: Color(0xFFECEFF4),      // Nord6
        surfaceContainerHighest: Color(0xFF3B4252), // Nord1
        onSurfaceVariant: Color(0xFFD8DEE9), // Nord4
        outline: Color(0xFF4C566A),        // Nord3
      );
}
