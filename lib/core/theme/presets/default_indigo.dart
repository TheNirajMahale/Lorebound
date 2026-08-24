import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

class DefaultIndigoPreset extends AppThemePreset {
  @override
  String get id => 'default_indigo';

  @override
  String get name => 'Default Indigo';

  @override
  ColorScheme get lightScheme => ColorScheme.fromSeed(
        seedColor: const Color(0xFF3F51B5), // Official Material Indigo
        brightness: Brightness.light,
      );

  @override
  ColorScheme get darkScheme => ColorScheme.fromSeed(
        seedColor: const Color(0xFF3F51B5), // Official Material Indigo
        brightness: Brightness.dark,
      );
}
