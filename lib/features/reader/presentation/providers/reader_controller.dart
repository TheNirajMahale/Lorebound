import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../domain/models/reader_config.dart';

class ReaderState {
  final ReaderConfig config;
  final String? bookPath;
  final bool isAsset;

  const ReaderState({
    required this.config,
    this.bookPath,
    this.isAsset = false,
  });

  ReaderState copyWith({
    ReaderConfig? config,
    String? bookPath,
    bool? isAsset,
  }) {
    return ReaderState(
      config: config ?? this.config,
      bookPath: bookPath ?? this.bookPath,
      isAsset: isAsset ?? this.isAsset,
    );
  }
}

class ReaderController extends Notifier<ReaderState> {
  static const _keyMode = 'reader_mode';
  static const _keyTheme = 'reader_theme_preset';
  static const _keyFontFamily = 'reader_font_family';
  static const _keyFontSize = 'reader_font_size';
  static const _keyLineSpacing = 'reader_line_spacing';
  static const _keyBrightness = 'reader_brightness';
  static const _keyTextAlignment = 'reader_text_alignment';
  static const _keyFontWeight = 'reader_font_weight';

  @override
  ReaderState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    
    final modeIndex = prefs.getInt(_keyMode);
    final themeIndex = prefs.getInt(_keyTheme);
    final alignmentIndex = prefs.getInt(_keyTextAlignment);
    final weightIndex = prefs.getInt(_keyFontWeight);

    final config = ReaderConfig(
      mode: modeIndex != null && modeIndex < ReaderMode.values.length ? ReaderMode.values[modeIndex] : ReaderMode.scroll,
      themePreset: themeIndex != null && themeIndex < ReaderThemePreset.values.length ? ReaderThemePreset.values[themeIndex] : ReaderThemePreset.white,
      fontFamily: prefs.getString(_keyFontFamily) ?? 'Inter',
      fontSize: prefs.getDouble(_keyFontSize) ?? 18.0,
      lineSpacing: prefs.getDouble(_keyLineSpacing) ?? 1.5,
      brightness: prefs.getDouble(_keyBrightness) ?? 1.0,
      textAlignment: alignmentIndex != null && alignmentIndex < TextAlign.values.length ? TextAlign.values[alignmentIndex] : TextAlign.left,
      fontWeight: weightIndex != null ? FontWeight.values.firstWhere((w) => w.value == weightIndex, orElse: () => FontWeight.normal) : FontWeight.normal,
    );

    return ReaderState(config: config);
  }

  void updateConfig(ReaderConfig newConfig) {
    state = state.copyWith(config: newConfig);
    final prefs = ref.read(sharedPrefsProvider);
    
    prefs.setInt(_keyMode, newConfig.mode.index);
    prefs.setInt(_keyTheme, newConfig.themePreset.index);
    prefs.setString(_keyFontFamily, newConfig.fontFamily);
    prefs.setDouble(_keyFontSize, newConfig.fontSize);
    prefs.setDouble(_keyLineSpacing, newConfig.lineSpacing);
    prefs.setDouble(_keyBrightness, newConfig.brightness);
    prefs.setInt(_keyTextAlignment, newConfig.textAlignment.index);
    prefs.setInt(_keyFontWeight, newConfig.fontWeight.value);
  }

  void loadBookFromAsset(String assetPath) {
    state = state.copyWith(bookPath: assetPath, isAsset: true);
  }

  void loadBookFromFile(String filePath) {
    state = state.copyWith(bookPath: filePath, isAsset: false);
  }
}

final readerControllerProvider = NotifierProvider<ReaderController, ReaderState>(() {
  return ReaderController();
});

class ReaderTabOrderNotifier extends Notifier<List<String>> {
  static const _key = 'reader_tab_order';
  static const defaultOrder = ['Navigation', 'Appearance', 'Tools'];

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final order = prefs.getStringList(_key);
    if (order != null && order.length == 3 && order.toSet().containsAll(defaultOrder)) {
      return order;
    }
    return defaultOrder;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final currentList = List<String>.from(state);
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);
    
    state = currentList;
    ref.read(sharedPrefsProvider).setStringList(_key, currentList);
  }
}

final readerTabOrderProvider = NotifierProvider<ReaderTabOrderNotifier, List<String>>(() {
  return ReaderTabOrderNotifier();
});
