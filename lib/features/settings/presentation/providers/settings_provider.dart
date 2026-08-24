import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/settings_model.dart';

/// The current search query for settings.
class SettingsSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String query) => state = query.toLowerCase();
}

final settingsSearchQueryProvider = NotifierProvider<SettingsSearchQueryNotifier, String>(() {
  return SettingsSearchQueryNotifier();
});

/// The static list of all searchable settings.
final settingsEntriesProvider = Provider<List<SettingsEntry>>((ref) {
  return const [
    SettingsEntry(
      id: 'theme_mode',
      title: 'Theme Mode',
      subtitle: 'Light, Dark, or System default',
      keywords: ['dark mode', 'light mode', 'theme', 'color', 'appearance'],
      icon: Icons.brightness_medium,
      route: '/more/settings/appearance',
    ),
    SettingsEntry(
      id: 'theme_presets',
      title: 'Theme Presets',
      subtitle: 'Choose from various color palettes',
      keywords: ['color', 'palette', 'catppuccin', 'nord', 'dracula', 'theme'],
      icon: Icons.palette_outlined,
      route: '/more/settings/appearance',
    ),
    SettingsEntry(
      id: 'amoled',
      title: 'Pitch Black',
      subtitle: 'True black background for AMOLED screens',
      keywords: ['amoled', 'black', 'dark', 'oled'],
      icon: Icons.dark_mode,
      route: '/more/settings/appearance',
    ),
    SettingsEntry(
      id: 'language',
      title: 'App Language',
      subtitle: 'Change the display language',
      keywords: ['language', 'locale', 'translate', 'english'],
      icon: Icons.language,
      route: '/more/settings/appearance',
    ),
    SettingsEntry(
      id: 'date_format',
      title: 'Date Format',
      subtitle: 'How dates are displayed',
      keywords: ['date', 'time', 'format'],
      icon: Icons.calendar_today,
      route: '/more/settings/appearance',
    ),
    SettingsEntry(
      id: 'default_category',
      title: 'Default Category',
      subtitle: 'Where new books are added',
      keywords: ['category', 'library', 'default'],
      icon: Icons.category,
      route: '/more/settings/library',
    ),
    SettingsEntry(
      id: 'chapter_swipe',
      title: 'Chapter Swipe Actions',
      subtitle: 'Configure left/right swipe in book detail',
      keywords: ['swipe', 'read', 'unread', 'action', 'chapter'],
      icon: Icons.swipe,
      route: '/more/settings/library',
    ),
    SettingsEntry(
      id: 'reader_tabs',
      title: 'Bottom Card Tab Order',
      subtitle: 'Reorder tabs in the reader',
      keywords: ['reader', 'tab', 'order', 'card', 'bottom'],
      icon: Icons.tab,
      route: '/more/settings/reader',
    ),
    SettingsEntry(
      id: 'hide_book_detail',
      title: 'Hide Book Detail',
      subtitle: 'Remove book info from reader bottom card',
      keywords: ['hide', 'book', 'detail', 'reader', 'info'],
      icon: Icons.visibility_off,
      route: '/more/settings/reader',
    ),
    SettingsEntry(
      id: 'storage_location',
      title: 'Storage Location',
      subtitle: 'Where books and data are saved',
      keywords: ['storage', 'folder', 'save', 'location', 'data'],
      icon: Icons.folder,
      route: '/more/settings/data-storage',
    ),
    SettingsEntry(
      id: 'clear_cache',
      title: 'Clear Cache',
      subtitle: 'Free up space used by temporary files',
      keywords: ['cache', 'clear', 'delete', 'space', 'storage'],
      icon: Icons.delete_sweep,
      route: '/more/settings/data-storage',
    ),
    SettingsEntry(
      id: 'export_library',
      title: 'Export Library',
      subtitle: 'Save your library data as CSV or JSON',
      keywords: ['export', 'save', 'backup', 'csv', 'json', 'data'],
      icon: Icons.file_download,
      route: '/more/settings/data-storage',
    ),
  ];
});

/// Returns settings entries filtered by the search query.
final settingsSearchProvider = Provider<List<SettingsEntry>>((ref) {
  final query = ref.watch(settingsSearchQueryProvider);
  final all = ref.watch(settingsEntriesProvider);
  
  if (query.isEmpty) return [];
  
  return all.where((entry) {
    return entry.title.toLowerCase().contains(query) ||
           entry.subtitle.toLowerCase().contains(query) ||
           entry.keywords.any((k) => k.toLowerCase().contains(query));
  }).toList();
});
