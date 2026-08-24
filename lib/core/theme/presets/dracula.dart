import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Dracula — a dark theme with purple, pink, and green accents.
/// Colors sourced from the official Dracula palette (draculatheme.com).
class DraculaPreset extends AppThemePreset {
  @override
  String get id => 'dracula';

  @override
  String get name => 'Dracula';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFF6C4BA3),       // Purple adapted for light
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE8DDF5),
        onPrimaryContainer: Color(0xFF3B2766),
        secondary: Color(0xFFD63384),     // Pink
        onSecondary: Colors.white,
        surface: Color(0xFFF8F8F2),        // Dracula foreground as light bg
        onSurface: Color(0xFF282A36),      // Dracula background as text
        surfaceContainerHighest: Color(0xFFEEEDE8),
        onSurfaceVariant: Color(0xFF44475A),
        outline: Color(0xFFBBBBC4),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFFBD93F9),       // Purple
        onPrimary: Color(0xFF282A36),
        primaryContainer: Color(0xFF44475A),
        onPrimaryContainer: Color(0xFFBD93F9),
        secondary: Color(0xFFFF79C6),     // Pink
        onSecondary: Color(0xFF282A36),
        surface: Color(0xFF282A36),        // Background
        onSurface: Color(0xFFF8F8F2),      // Foreground
        surfaceContainerHighest: Color(0xFF44475A), // Current Line
        onSurfaceVariant: Color(0xFFBFBFBF),
        outline: Color(0xFF6272A4),        // Comment blue
      );
}
