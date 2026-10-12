import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'theme_config.dart';
import 'presets/preset_catalog.dart';

/// Applies AMOLED black to a dark theme if requested
ColorScheme _applyAmoledIfRequested(ColorScheme scheme, ThemeConfig config) {
  if (scheme.brightness == Brightness.dark && config.useAmoledBlack) {
    return scheme.copyWith(
      surface: const Color(0xFF000000), // Pure OLED black
      surfaceContainer: const Color(0xFF121212), // Deep grey cards
      surfaceContainerHigh: const Color(0xFF181818),
      surfaceContainerHighest: const Color(0xFF1E1E1E),
      outlineVariant: const Color(0xFF2C2C2C),
    );
  }
  return scheme;
}

/// Builds the master ThemeData
ThemeData buildAppTheme(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;
  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: colorScheme.brightness,
    fontFamily: AppTypography.fontFamily,
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme);

  return baseTheme.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      surfaceTintColor: colorScheme.surfaceTint,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: colorScheme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: colorScheme.brightness == Brightness.dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: colorScheme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation: 2,
      backgroundColor: colorScheme.surface,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    bottomAppBarTheme: BottomAppBarThemeData(
      elevation: 2,
      color: colorScheme.surface,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.onSurface.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),

    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
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
