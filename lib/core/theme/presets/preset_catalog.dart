import 'app_theme_preset.dart';
import 'default_indigo.dart';
import 'midnight_dusk.dart';

class PresetCatalog {
  static final List<AppThemePreset> allPresets = [
    DefaultIndigoPreset(),
    MidnightDuskPreset(),
  ];

  static AppThemePreset getPresetById(String id) {
    return allPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => allPresets.first,
    );
  }
}
