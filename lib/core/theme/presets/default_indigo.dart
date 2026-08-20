import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

class DefaultIndigoPreset extends AppThemePreset {
  @override
  String get id => 'default_indigo';

  @override
  String get name => 'Default Indigo';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF4338CA), // Deep Indigo
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0E7FF),
        onPrimaryContainer: Color(0xFF312E81),
        secondary: Color(0xFF92400E),
        onSecondary: Colors.white,
        surface: Color(0xFFFDFBF7), // Warm paper
        onSurface: Color(0xFF1E1B18),
        surfaceContainerHighest: Color(0xFFF4EFE6),
        onSurfaceVariant: Color(0xFF5C5852),
        outline: Color(0xFFD6D1C9),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFF818CF8),
        onPrimary: Color(0xFF1E1B4B),
        primaryContainer: Color(0xFF3730A3),
        onPrimaryContainer: Color(0xFFE0E7FF),
        secondary: Color(0xFFFCD34D),
        onSecondary: Color(0xFF451A03),
        surface: Color(0xFF121212), // Deep grey
        onSurface: Color(0xFFE4DFDA),
        surfaceContainerHighest: Color(0xFF1F1E1B),
        onSurfaceVariant: Color(0xFFA39F99),
        outline: Color(0xFF4A4743),
      );
}
