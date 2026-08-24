import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Strawberry Daiquiri — a vibrant warm red/pink theme.
/// Inspired by Mihon/Tachiyomi community themes.
class StrawberryDaiquiriPreset extends AppThemePreset {
  @override
  String get id => 'strawberry_daiquiri';

  @override
  String get name => 'Strawberry Daiquiri';

  @override
  ColorScheme get lightScheme => const ColorScheme.light(
        primary: Color(0xFFED4A65),       // Strawberry red
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFDADD),
        onPrimaryContainer: Color(0xFF5C0F1A),
        secondary: Color(0xFFD4586A),
        onSecondary: Colors.white,
        surface: Color(0xFFFFF8F8),        // Warm near-white
        onSurface: Color(0xFF2C1518),
        surfaceContainerHighest: Color(0xFFF5E5E7),
        onSurfaceVariant: Color(0xFF6B4248),
        outline: Color(0xFFD4AFB4),
      );

  @override
  ColorScheme get darkScheme => const ColorScheme.dark(
        primary: Color(0xFFED4A65),       // Strawberry red
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF5C0F1A),
        onPrimaryContainer: Color(0xFFFFDADD),
        secondary: Color(0xFFFF8A97),
        onSecondary: Color(0xFF3B0A12),
        surface: Color(0xFF1A1012),        // Deep dark warm
        onSurface: Color(0xFFE8DFE0),
        surfaceContainerHighest: Color(0xFF2C1F21),
        onSurfaceVariant: Color(0xFFD0C0C2),
        outline: Color(0xFF7A6568),
      );
}
