import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/presets/preset_catalog.dart';
import '../widgets/theme_preset_card.dart';
import '../widgets/dynamic_color_card.dart';
import '../../domain/models/date_format_preference.dart';
import '../providers/date_format_controller.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          // Theme Section
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Text(
              'Theme',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            title: const Text('Theme mode'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                ],
                selected: {themeConfig.mode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  ref.read(themeProvider.notifier).updateMode(newSelection.first);
                },
              ),
            ),
          ),
          
          // SwitchListTile for Dynamic color was removed from here
          
          // Only show AMOLED toggle if not in light mode
          if (themeConfig.mode != ThemeMode.light)
            SwitchListTile(
              title: const Text('Pitch black'),
              subtitle: const Text('Use true black background for AMOLED screens'),
              value: themeConfig.useAmoledBlack,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleAmoledBlack(value);
              },
            ),
            
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Text('Theme presets'),
          ),
          
          // Theme preset carousel
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: PresetCatalog.allPresets.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return DynamicColorCard(
                    isSelected: themeConfig.useMaterialYou,
                    onTap: () {
                      ref.read(themeProvider.notifier).toggleMaterialYou(true);
                    },
                  );
                }
                
                final preset = PresetCatalog.allPresets[index - 1];
                return ThemePresetCard(
                  preset: preset,
                  // The preset is only selected if we aren't using Material You
                  isSelected: !themeConfig.useMaterialYou && themeConfig.presetId == preset.id,
                  onTap: () {
                    // Turn off material you when a specific preset is picked
                    ref.read(themeProvider.notifier).toggleMaterialYou(false);
                    ref.read(themeProvider.notifier).updatePreset(preset.id);
                  },
                );
              },
            ),
          ),
          
          const Divider(),
          
          // Display Section
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Text(
              'Display',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            title: const Text('Date format'),
            subtitle: Text(ref.watch(dateFormatProvider).label),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              final currentPref = ref.read(dateFormatProvider);
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                          child: Text(
                            'Date Format',
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                        ...DateFormatPreference.values.map((pref) {
                          final isSelected = pref == currentPref;
                          return ListTile(
                            leading: Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                            title: Text(pref.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Example: ${pref.format(DateTime.now())}'),
                            selected: isSelected,
                            onTap: () {
                              ref.read(dateFormatProvider.notifier).updatePreference(pref);
                              Navigator.of(ctx).pop();
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
