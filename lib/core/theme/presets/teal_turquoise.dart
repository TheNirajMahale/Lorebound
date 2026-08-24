import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Teal & Turquoise — fresh ocean-toned greens and blues.
/// A calming, nature-inspired palette for relaxed reading sessions.
class TealTurquoisePreset extends AppThemePreset {
  @override
  String get id => 'teal_turquoise';

  @override
  String get name => 'Teal & Turquoise';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF00796B),       // Teal 700
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFB2DFDB),
        onPrimaryContainer: Color(0xFF003D33),
        secondary: Color(0xFF00ACC1),     // Cyan 600
        onSecondary: Colors.white,
        surface: Color(0xFFF5FAFA),        // Cool near-white
        onSurface: Color(0xFF1A2C2A),
        surfaceContainerHighest: Color(0xFFE0F2F1),
        onSurfaceVariant: Color(0xFF4A6560),
        outline: Color(0xFFB2CECA),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFF4DB6AC),       // Teal 300
        onPrimary: Color(0xFF003731),
        primaryContainer: Color(0xFF00695C),
        onPrimaryContainer: Color(0xFFB2DFDB),
        secondary: Color(0xFF4DD0E1),     // Cyan 300
        onSecondary: Color(0xFF003741),
        surface: Color(0xFF0F1E1C),        // Deep dark teal
        onSurface: Color(0xFFD4E8E5),
        surfaceContainerHighest: Color(0xFF1A2C2A),
        onSurfaceVariant: Color(0xFFA3BDB9),
        outline: Color(0xFF4F6965),
      );
}
