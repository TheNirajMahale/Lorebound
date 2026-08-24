import 'app_theme_preset.dart';
import 'default_indigo.dart';
import 'midnight_dusk.dart';
import 'catppuccin_mocha.dart';
import 'nord.dart';
import 'tokyo_night.dart';
import 'dracula.dart';
import 'solarized.dart';
import 'gruvbox.dart';
import 'strawberry_daiquiri.dart';
import 'teal_turquoise.dart';

class PresetCatalog {
  static final List<AppThemePreset> allPresets = [
    DefaultIndigoPreset(),
    MidnightDuskPreset(),
    CatppuccinMochaPreset(),
    NordPreset(),
    TokyoNightPreset(),
    DraculaPreset(),
    SolarizedPreset(),
    GruvboxPreset(),
    StrawberryDaiquiriPreset(),
    TealTurquoisePreset(),
  ];

  static AppThemePreset getPresetById(String id) {
    if (id == 'default') {
      id = 'default_indigo';
    }
    return allPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => allPresets.first,
    );
  }
}

