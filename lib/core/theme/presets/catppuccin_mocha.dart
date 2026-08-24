import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Catppuccin Mocha (dark) + Latte (light) — warm pastel community theme.
/// Colors sourced from the official Catppuccin palette specification.
class CatppuccinMochaPreset extends AppThemePreset {
  @override
  String get id => 'catppuccin_mocha';

  @override
  String get name => 'Catppuccin';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF8839EF),       // Mauve (Latte)
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE8D5F5),
        onPrimaryContainer: Color(0xFF3B1261),
        secondary: Color(0xFFEA76CB),     // Pink (Latte)
        onSecondary: Colors.white,
        surface: Color(0xFFEFF1F5),        // Base (Latte)
        onSurface: Color(0xFF4C4F69),      // Text (Latte)
        surfaceContainerHighest: Color(0xFFE6E9EF), // Mantle (Latte)
        onSurfaceVariant: Color(0xFF6C6F85), // Subtext0 (Latte)
        outline: Color(0xFFACB0BE),        // Overlay0 (Latte)
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFFCBA6F7),       // Mauve (Mocha)
        onPrimary: Color(0xFF1E1E2E),
        primaryContainer: Color(0xFF45475A),
        onPrimaryContainer: Color(0xFFCBA6F7),
        secondary: Color(0xFFF5C2E7),     // Pink (Mocha)
        onSecondary: Color(0xFF1E1E2E),
        surface: Color(0xFF1E1E2E),        // Base (Mocha)
        onSurface: Color(0xFFCDD6F4),      // Text (Mocha)
        surfaceContainerHighest: Color(0xFF313244), // Surface0 (Mocha)
        onSurfaceVariant: Color(0xFFA6ADC8), // Subtext0 (Mocha)
        outline: Color(0xFF6C7086),        // Overlay0 (Mocha)
      );
}
