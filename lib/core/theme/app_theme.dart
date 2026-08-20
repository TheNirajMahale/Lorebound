import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'theme_config.dart';
import 'presets/preset_catalog.dart';

/// Applies AMOLED black to a dark theme if requested
ColorScheme _applyAmoledIfRequested(ColorScheme scheme, ThemeConfig config) {
  if (scheme.brightness == Brightness.dark && config.useAmoledBlack) {
    return scheme.copyWith(
      surface: const Color(0xFF000000), // Pure OLED black
      surfaceContainerHighest: const Color(0xFF121212), // Deep grey cards
    );
  }
  return scheme;
}

/// Builds the master ThemeData
ThemeData buildAppTheme(ColorScheme colorScheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: AppTypography.fontFamily,
    scaffoldBackgroundColor: colorScheme.surface,
    
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    ),
  );
}

/// A wrapper widget that provides the dynamic theme to MaterialApp
class LoreboundThemeBuilder extends StatelessWidget {
  final ThemeConfig config;
  final Widget Function(ThemeData light, ThemeData dark) builder;

  const LoreboundThemeBuilder({
    super.key,
    required this.config,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final preset = PresetCatalog.getPresetById(config.presetId);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 1. Determine base color schemes
        ColorScheme lightScheme = preset.lightScheme;
        ColorScheme darkScheme = preset.darkScheme;

        // 2. Apply Material You if enabled and available
        if (config.useMaterialYou) {
          if (lightDynamic != null) lightScheme = lightDynamic;
          if (darkDynamic != null) darkScheme = darkDynamic;
        }

        // 3. Apply AMOLED Black if requested
        darkScheme = _applyAmoledIfRequested(darkScheme, config);

        // 4. Build Themes
        final lightTheme = buildAppTheme(lightScheme);
        final darkTheme = buildAppTheme(darkScheme);

        return builder(lightTheme, darkTheme);
      },
    );
  }
}
