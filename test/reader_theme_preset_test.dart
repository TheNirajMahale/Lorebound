import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/reader/domain/models/reader_config.dart';

void main() {
  group('Reader Theme Token System & Subtle Elevation Tests', () {
    test('All presets provide distinct, harmonious canvas and card colors with subtle elevation', () {
      for (final preset in ReaderThemePreset.values) {
        expect(preset.backgroundColor, isNotNull);
        expect(preset.cardBackgroundColor, isNotNull);
        expect(preset.toolbarBackgroundColor, isNotNull);
        expect(preset.accentColor, isNotNull);
        expect(preset.borderColor, isNotNull);
        expect(preset.shadowColor, isNotNull);
        expect(preset.cardContainerColor, isNotNull);
        expect(preset.badgeBackgroundColor, isNotNull);

        // Card color should NOT be identical to canvas background (subtle elevation step)
        expect(
          preset.cardBackgroundColor != preset.backgroundColor,
          isTrue,
          reason: 'Preset ${preset.name} card background must have subtle elevation distinct from canvas',
        );
      }
    });

    test('White preset subtle elevation tokens', () {
      const preset = ReaderThemePreset.white;
      expect(preset.backgroundColor, const Color(0xFFFFFFFF));
      expect(preset.cardBackgroundColor, const Color(0xFFF6F7F9));
      expect(preset.textColor, const Color(0xFF121212));
      expect(preset.isDark, isFalse);
    });

    test('Sepia preset subtle elevation parchment tokens', () {
      const preset = ReaderThemePreset.sepia;
      expect(preset.backgroundColor, const Color(0xFFFBF0D9));
      expect(preset.cardBackgroundColor, const Color(0xFFF2E5C8));
      expect(preset.cardContainerColor, const Color(0xFFF9F0DC));
      expect(preset.accentColor, const Color(0xFF945219));
      expect(preset.isDark, isFalse);
    });

    test('AMOLED Black preset subtle elevation tokens', () {
      const preset = ReaderThemePreset.black;
      expect(preset.backgroundColor, const Color(0xFF000000));
      expect(preset.cardBackgroundColor, const Color(0xFF141414));
      expect(preset.toolbarBackgroundColor, const Color(0xFF1A1A1A));
      expect(preset.isDark, isTrue);
    });

    test('ReaderConfig forwards all tokens directly from themePreset', () {
      const config = ReaderConfig(themePreset: ReaderThemePreset.sepia);
      expect(config.backgroundColor, ReaderThemePreset.sepia.backgroundColor);
      expect(config.cardBackgroundColor, ReaderThemePreset.sepia.cardBackgroundColor);
      expect(config.toolbarBackgroundColor, ReaderThemePreset.sepia.toolbarBackgroundColor);
      expect(config.cardContainerColor, ReaderThemePreset.sepia.cardContainerColor);
      expect(config.accentColor, ReaderThemePreset.sepia.accentColor);
      expect(config.borderColor, ReaderThemePreset.sepia.borderColor);
      expect(config.shadowColor, ReaderThemePreset.sepia.shadowColor);
      expect(config.badgeBackgroundColor, ReaderThemePreset.sepia.badgeBackgroundColor);
      expect(config.dividerColor, ReaderThemePreset.sepia.dividerColor);
      expect(config.searchHighlightColor, ReaderThemePreset.sepia.searchHighlightColor);
      expect(config.activeSearchHighlightColor, ReaderThemePreset.sepia.activeSearchHighlightColor);
      expect(config.activeSearchTextColor, ReaderThemePreset.sepia.activeSearchTextColor);
    });
  });
}
