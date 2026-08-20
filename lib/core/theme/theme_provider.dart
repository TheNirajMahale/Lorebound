import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_config.dart';

class ThemeNotifier extends Notifier<ThemeConfig> {
  @override
  ThemeConfig build() {
    // Default starting state
    // TODO: Load saved theme preference from local storage (Isar) here.
    return const ThemeConfig();
  }

  void updateMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  void updatePreset(String presetId) {
    state = state.copyWith(presetId: presetId);
  }

  void toggleAmoledBlack(bool enabled) {
    state = state.copyWith(useAmoledBlack: enabled);
  }

  void toggleMaterialYou(bool enabled) {
    state = state.copyWith(useMaterialYou: enabled);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeConfig>(() {
  return ThemeNotifier();
});
