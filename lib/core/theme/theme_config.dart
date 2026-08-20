import 'package:flutter/material.dart';

class ThemeConfig {
  final ThemeMode mode;
  final String presetId;
  final bool useAmoledBlack;
  final bool useMaterialYou;

  const ThemeConfig({
    this.mode = ThemeMode.system,
    this.presetId = 'default_indigo',
    this.useAmoledBlack = false,
    this.useMaterialYou = true,
  });

  ThemeConfig copyWith({
    ThemeMode? mode,
    String? presetId,
    bool? useAmoledBlack,
    bool? useMaterialYou,
  }) {
    return ThemeConfig(
      mode: mode ?? this.mode,
      presetId: presetId ?? this.presetId,
      useAmoledBlack: useAmoledBlack ?? this.useAmoledBlack,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
    );
  }
}
