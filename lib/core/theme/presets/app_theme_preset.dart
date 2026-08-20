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
}
