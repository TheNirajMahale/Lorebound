import 'package:flutter/material.dart';

enum ReaderMode {
  scroll,
  paginated,
}

enum ReaderThemePreset {
  white,
  sepia,
  grey,
  dark,
  black,
}

class ReaderConfig {
  final ReaderMode mode;
  final ReaderThemePreset themePreset;
  final String fontFamily;
  final double fontSize;
  final double lineSpacing;
  final double brightness;
  final TextAlign textAlignment;
  final FontWeight fontWeight;
  final bool autoScrollEnabled;
  final double autoScrollSpeed;
  final bool bionicReadingEnabled;
  final bool autoLookupOnSelection;

  const ReaderConfig({
    this.mode = ReaderMode.scroll,
    this.themePreset = ReaderThemePreset.white,
    this.fontFamily = 'Inter',
    this.fontSize = 18.0,
    this.lineSpacing = 1.5,
    this.brightness = 1.0,
    this.textAlignment = TextAlign.left,
    this.fontWeight = FontWeight.normal,
    this.autoScrollEnabled = false,
    this.autoScrollSpeed = 40.0,
    this.bionicReadingEnabled = false,
    this.autoLookupOnSelection = true,
  });

  ReaderConfig copyWith({
    ReaderMode? mode,
    ReaderThemePreset? themePreset,
    String? fontFamily,
    double? fontSize,
    double? lineSpacing,
    double? brightness,
    TextAlign? textAlignment,
    FontWeight? fontWeight,
    bool? autoScrollEnabled,
    double? autoScrollSpeed,
    bool? bionicReadingEnabled,
    bool? autoLookupOnSelection,
  }) {
    return ReaderConfig(
      mode: mode ?? this.mode,
      themePreset: themePreset ?? this.themePreset,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      brightness: brightness ?? this.brightness,
      textAlignment: textAlignment ?? this.textAlignment,
      fontWeight: fontWeight ?? this.fontWeight,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      bionicReadingEnabled: bionicReadingEnabled ?? this.bionicReadingEnabled,
      autoLookupOnSelection: autoLookupOnSelection ?? this.autoLookupOnSelection,
    );
  }

  /// Background canvas color for the current preset
  Color get backgroundColor => themePreset.backgroundColor;

  /// Primary body text color
  Color get textColor => themePreset.textColor;

  /// Secondary/subtle text color
  Color get secondaryTextColor => themePreset.secondaryTextColor;

  /// Subtly elevated surface color for selection card and panels
  Color get cardBackgroundColor => themePreset.cardBackgroundColor;

  /// Nested container / quote / explanation body color matching reader theme
  Color get cardContainerColor => themePreset.cardContainerColor;

  /// Floating toolbar pill background color
  Color get toolbarBackgroundColor => themePreset.toolbarBackgroundColor;

  /// Badge/chip background color (phonetics, tags)
  Color get badgeBackgroundColor => themePreset.badgeBackgroundColor;

  /// Accent / indicator color matching the reader theme
  Color get accentColor => themePreset.accentColor;

  /// Subtle border token separating card and toolbar from reading canvas
  Color get borderColor => themePreset.borderColor;

  /// Elevated drop shadow color
  Color get shadowColor => themePreset.shadowColor;

  /// Divider color between card sections
  Color get dividerColor => themePreset.dividerColor;

  /// In-page search match highlight background
  Color get searchHighlightColor => themePreset.searchHighlightColor;

  /// In-page active search match highlight background
  Color get activeSearchHighlightColor => themePreset.activeSearchHighlightColor;

  /// Text color for the active search highlight
  Color get activeSearchTextColor => themePreset.activeSearchTextColor;

  /// Whether the preset is a dark/night variant
  bool get isDark => themePreset.isDark;
}

/// Tokenized design system for reader theme presets
extension ReaderThemePresetExtension on ReaderThemePreset {
  /// Base canvas background color
  Color get backgroundColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFFFFFFFF);
      case ReaderThemePreset.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderThemePreset.grey:
        return const Color(0xFF333333);
      case ReaderThemePreset.dark:
        return const Color(0xFF121212);
      case ReaderThemePreset.black:
        return const Color(0xFF000000);
    }
  }

  /// Primary body text color
  Color get textColor {
    switch (this) {
      case ReaderThemePreset.white:
      case ReaderThemePreset.sepia:
        return const Color(0xFF121212);
      case ReaderThemePreset.grey:
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return const Color(0xFFE0E0E0);
    }
  }

  /// Secondary/muted text color for metadata, word count, phonetics
  Color get secondaryTextColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFF5F6368);
      case ReaderThemePreset.sepia:
        return const Color(0xFF6E553F);
      case ReaderThemePreset.grey:
        return const Color(0xFFA0A0A0);
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Subtly elevated surface color for selection cards, bottom sheets, and panels.
  /// Harmonizes directly with the reader preset rather than global app theme.
  Color get cardBackgroundColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFFF6F7F9); // Crisp subtle elevation on white canvas
      case ReaderThemePreset.sepia:
        return const Color(0xFFF2E5C8); // Warm parchment elevation on sepia canvas
      case ReaderThemePreset.grey:
        return const Color(0xFF3C3C3C); // Subtle lighter elevation on 0xFF333333
      case ReaderThemePreset.dark:
        return const Color(0xFF1E1E1E); // Elevated dark surface on 0xFF121212
      case ReaderThemePreset.black:
        return const Color(0xFF141414); // Subtle elevation on pure AMOLED black
    }
  }

  /// Nested container / quote / explanation body box color
  Color get cardContainerColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFFFFFFFF);
      case ReaderThemePreset.sepia:
        return const Color(0xFFF9F0DC);
      case ReaderThemePreset.grey:
        return const Color(0xFF464646);
      case ReaderThemePreset.dark:
        return const Color(0xFF262626);
      case ReaderThemePreset.black:
        return const Color(0xFF1E1E1E);
    }
  }

  /// Pill/floating surface color for the floating selection toolbar
  Color get toolbarBackgroundColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFFFFFFFF);
      case ReaderThemePreset.sepia:
        return const Color(0xFFF4EAD0);
      case ReaderThemePreset.grey:
        return const Color(0xFF404040);
      case ReaderThemePreset.dark:
        return const Color(0xFF222222);
      case ReaderThemePreset.black:
        return const Color(0xFF1A1A1A);
    }
  }

  /// Harmonious accent/tint color for reader indicators, icons, and active tabs
  Color get accentColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFF2563EB); // Royal Blue
      case ReaderThemePreset.sepia:
        return const Color(0xFF945219); // Warm amber leather
      case ReaderThemePreset.grey:
        return const Color(0xFF60A5FA); // Soft Sky Blue
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return const Color(0xFF93C5FD); // Radiant Ice Blue
    }
  }

  /// Subtle border token separating card and toolbar from the reading canvas
  Color get borderColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0x1F000000); // 12% black
      case ReaderThemePreset.sepia:
        return const Color(0x22785226); // Subtle warm brown border
      case ReaderThemePreset.grey:
        return const Color(0x28FFFFFF); // 16% white
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return const Color(0x22FFFFFF); // 13% white
    }
  }

  /// Elevated drop shadow color
  Color get shadowColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0x26000000); // 15% black
      case ReaderThemePreset.sepia:
        return const Color(0x334D3418); // Warm deep parchment shadow
      case ReaderThemePreset.grey:
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return const Color(0x55000000); // 33% black
    }
  }

  /// Inner badge/chip background for dictionary phonetic badges and provider tags
  Color get badgeBackgroundColor {
    switch (this) {
      case ReaderThemePreset.white:
        return const Color(0xFFE9EDF5);
      case ReaderThemePreset.sepia:
        return const Color(0xFFE6D6B4);
      case ReaderThemePreset.grey:
        return const Color(0xFF2E2E2E);
      case ReaderThemePreset.dark:
        return const Color(0xFF171717);
      case ReaderThemePreset.black:
        return const Color(0xFF0C0C0C);
    }
  }

  /// Inner divider line color
  Color get dividerColor => textColor.withValues(alpha: 0.10);

  /// Search highlight background for inactive matches
  Color get searchHighlightColor => const Color(0x66FFC107);

  /// Search highlight background for active/current match
  Color get activeSearchHighlightColor => const Color(0xFFFF9800);

  /// Text color for active search highlight
  Color get activeSearchTextColor => const Color(0xFF000000);

  /// Whether this preset is a dark/night variant
  bool get isDark {
    switch (this) {
      case ReaderThemePreset.white:
      case ReaderThemePreset.sepia:
        return false;
      case ReaderThemePreset.grey:
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return true;
    }
  }
}
