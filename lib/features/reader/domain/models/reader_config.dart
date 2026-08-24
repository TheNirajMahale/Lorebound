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

  const ReaderConfig({
    this.mode = ReaderMode.scroll,
    this.themePreset = ReaderThemePreset.white,
    this.fontFamily = 'Inter',
    this.fontSize = 18.0,
    this.lineSpacing = 1.5,
    this.brightness = 1.0,
    this.textAlignment = TextAlign.left,
    this.fontWeight = FontWeight.normal,
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
    );
  }

  /// Returns the background color for the current preset
  Color get backgroundColor {
    switch (themePreset) {
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

  /// Returns the text color for the current preset
  Color get textColor {
    switch (themePreset) {
      case ReaderThemePreset.white:
      case ReaderThemePreset.sepia:
        return const Color(0xFF121212);
      case ReaderThemePreset.grey:
      case ReaderThemePreset.dark:
      case ReaderThemePreset.black:
        return const Color(0xFFE0E0E0);
    }
  }
}
