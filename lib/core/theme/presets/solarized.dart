import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Solarized — Ethan Schoonover's precision-engineered warm/cool palette.
/// Colors sourced from the official Solarized specification (ethanschoonover.com/solarized).
class SolarizedPreset extends AppThemePreset {
  @override
  String get id => 'solarized';

  @override
  String get name => 'Solarized';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF268BD2),       // Blue
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD1E8F7),
        onPrimaryContainer: Color(0xFF073642),
        secondary: Color(0xFF2AA198),     // Cyan
        onSecondary: Colors.white,
        surface: Color(0xFFFDF6E3),        // Base3 — light cream
        onSurface: Color(0xFF657B83),      // Base00
        surfaceContainerHighest: Color(0xFFEEE8D5), // Base2
        onSurfaceVariant: Color(0xFF586E75), // Base01
        outline: Color(0xFF93A1A1),        // Base1
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFF268BD2),       // Blue
        onPrimary: Color(0xFFFDF6E3),
        primaryContainer: Color(0xFF073642),
        onPrimaryContainer: Color(0xFF268BD2),
        secondary: Color(0xFF2AA198),     // Cyan
        onSecondary: Color(0xFF002B36),
        surface: Color(0xFF002B36),        // Base03 — dark teal
        onSurface: Color(0xFF839496),      // Base0
        surfaceContainerHighest: Color(0xFF073642), // Base02
        onSurfaceVariant: Color(0xFF93A1A1), // Base1
        outline: Color(0xFF586E75),        // Base01
      );
}
