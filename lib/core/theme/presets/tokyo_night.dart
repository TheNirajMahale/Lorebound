import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Tokyo Night — neon-accented deep blue-grey theme inspired by Tokyo city lights.
/// Colors sourced from the Tokyo Night VS Code theme palette.
class TokyoNightPreset extends AppThemePreset {
  @override
  String get id => 'tokyo_night';

  @override
  String get name => 'Tokyo Night';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF34548A),       // Blue accent (day)
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD5E1F2),
        onPrimaryContainer: Color(0xFF1A2744),
        secondary: Color(0xFF965027),     // Orange accent
        onSecondary: Colors.white,
        surface: Color(0xFFD5D6DB),        // Day background
        onSurface: Color(0xFF343B59),
        surfaceContainerHighest: Color(0xFFC4C5CA),
        onSurfaceVariant: Color(0xFF4E5579),
        outline: Color(0xFF9699A3),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFF7AA2F7),       // Blue accent (storm)
        onPrimary: Color(0xFF1A1B26),
        primaryContainer: Color(0xFF283457),
        onPrimaryContainer: Color(0xFF7AA2F7),
        secondary: Color(0xFFFF9E64),     // Orange accent
        onSecondary: Color(0xFF1A1B26),
        surface: Color(0xFF1A1B26),        // Storm background
        onSurface: Color(0xFFC0CAF5),      // Storm foreground
        surfaceContainerHighest: Color(0xFF24283B), // Storm surface
        onSurfaceVariant: Color(0xFF9AA5CE),
        outline: Color(0xFF414868),
      );
}
