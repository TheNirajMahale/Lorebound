import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Gruvbox — a retro groove color scheme with warm browns and muted accents.
/// Colors sourced from the Gruvbox palette (github.com/morhetz/gruvbox).
class GruvboxPreset extends AppThemePreset {
  @override
  String get id => 'gruvbox';

  @override
  String get name => 'Gruvbox';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFFCC241D),       // Red
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFF2D5D3),
        onPrimaryContainer: Color(0xFF5C110E),
        secondary: Color(0xFF98971A),     // Green
        onSecondary: Colors.white,
        surface: Color(0xFFFBF1C7),        // Light bg
        onSurface: Color(0xFF3C3836),      // Dark fg
        surfaceContainerHighest: Color(0xFFF2E5BC),
        onSurfaceVariant: Color(0xFF504945),
        outline: Color(0xFFBDAE93),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFFFB4934),       // Red (bright)
        onPrimary: Color(0xFF282828),
        primaryContainer: Color(0xFF3C3836),
        onPrimaryContainer: Color(0xFFFB4934),
        secondary: Color(0xFFB8BB26),     // Green (bright)
        onSecondary: Color(0xFF282828),
        surface: Color(0xFF282828),        // Dark bg
        onSurface: Color(0xFFEBDBB2),      // Light fg
        surfaceContainerHighest: Color(0xFF3C3836),
        onSurfaceVariant: Color(0xFFA89984),
        outline: Color(0xFF665C54),
      );
}
