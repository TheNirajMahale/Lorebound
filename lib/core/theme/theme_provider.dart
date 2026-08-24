import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_config.dart';

import '../providers/shared_prefs_provider.dart';

class ThemeNotifier extends Notifier<ThemeConfig> {
  static const _keyMode = 'theme_mode';
  static const _keyPreset = 'theme_preset';
  static const _keyAmoled = 'theme_amoled';
  static const _keyMaterialYou = 'theme_material_you';

  @override
  ThemeConfig build() {
    final prefs = ref.watch(sharedPrefsProvider);
    
    final modeIndex = prefs.getInt(_keyMode);
    final mode = modeIndex != null ? ThemeMode.values[modeIndex] : ThemeMode.system;
    
    final presetId = prefs.getString(_keyPreset) ?? 'default_indigo';
    final amoled = prefs.getBool(_keyAmoled) ?? false;
    final materialYou = prefs.getBool(_keyMaterialYou) ?? true;

    return ThemeConfig(
      mode: mode,
      presetId: presetId,
      useAmoledBlack: amoled,
      useMaterialYou: materialYou,
    );
  }

  void updateMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    ref.read(sharedPrefsProvider).setInt(_keyMode, mode.index);
  }

  void updatePreset(String presetId) {
    state = state.copyWith(presetId: presetId);
    ref.read(sharedPrefsProvider).setString(_keyPreset, presetId);
  }

  void toggleAmoledBlack(bool enabled) {
    state = state.copyWith(useAmoledBlack: enabled);
    ref.read(sharedPrefsProvider).setBool(_keyAmoled, enabled);
  }

  void toggleMaterialYou(bool enabled) {
    state = state.copyWith(useMaterialYou: enabled);
    ref.read(sharedPrefsProvider).setBool(_keyMaterialYou, enabled);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeConfig>(() {
  return ThemeNotifier();
});
