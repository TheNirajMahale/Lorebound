import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

class MidnightDuskPreset extends AppThemePreset {
  @override
  String get id => 'midnight_dusk';

  @override
  String get name => 'Midnight Dusk';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFFF02475), // Vibrant pink/red
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFD9E2),
        onPrimaryContainer: Color(0xFF3F0017),
        secondary: Color(0xFFF02475),
        onSecondary: Colors.white,
        surface: Color(0xFFF7F5F8),
        onSurface: Color(0xFF1F1A1C),
        surfaceContainerHighest: Color(0xFFF1E5E7),
        onSurfaceVariant: Color(0xFF524345),
        outline: Color(0xFF847376),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFFF02475), 
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF5D0024),
        onPrimaryContainer: Color(0xFFFFD9E2),
        secondary: Color(0xFFF02475),
        onSecondary: Colors.white,
        surface: Color(0xFF16151D), // Iconic midnight dusk blue-black
        onSurface: Color(0xFFE4E1E6),
        surfaceContainerHighest: Color(0xFF201F27),
        onSurfaceVariant: Color(0xFFD7C1C4),
        outline: Color(0xFF9E8C90),
      );
}
