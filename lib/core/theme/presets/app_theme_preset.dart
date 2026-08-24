import 'package:flutter/material.dart';

abstract class AppThemePreset {
  /// Unique identifier to save in the local database (e.g., 'midnight_dusk')
  String get id;
  
  /// Human-readable name shown in the UI dropdown
  String get name;
  
  /// The specific color scheme for light mode
  ColorScheme get lightScheme;
  
  /// The specific color scheme for dark mode
  ColorScheme get darkScheme;

  /// Primary accent color for the settings theme carousel swatch
  Color get previewColor => darkScheme.primary;

  /// Surface color for the settings theme carousel skeleton background
  Color get previewSurface => darkScheme.surface;
}
