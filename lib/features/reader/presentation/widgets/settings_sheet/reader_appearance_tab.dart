import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
import 'package:lorebound/core/widgets/expressive_chip.dart';
import '../../../domain/models/reader_config.dart';
import '../../providers/reader_controller.dart';

class ReaderAppearanceTab extends ConsumerWidget {
  const ReaderAppearanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = ref.watch(readerControllerProvider).config;
    final notifier = ref.read(readerControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Reading Mode
        Text(
          'Reading Mode',
          style: TextStyle(
            fontSize: AppTypography.sm,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ReaderMode>(
          segments: const [
            ButtonSegment(
              value: ReaderMode.scroll,
              label: Text('Vertical Scroll'),
              icon: Icon(Icons.swap_vert),
            ),
            ButtonSegment(
              value: ReaderMode.paginated,
              label: Text('Paginated'),
              icon: Icon(Icons.menu_book),
            ),
          ],
          selected: {config.mode},
          onSelectionChanged: (Set<ReaderMode> newSelection) {
            final newMode = newSelection.first;
            notifier.updateConfig(
              config.copyWith(
                mode: newMode,
                autoScrollEnabled: newMode == ReaderMode.scroll ? config.autoScrollEnabled : false,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Theme Presets
        Text(
          'Theme Preset',
          style: TextStyle(
            fontSize: AppTypography.sm,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ReaderThemePreset.values.map((preset) {
              final isSelected = config.themePreset == preset;
              return ExpressiveChip(
                label: preset.name.toUpperCase(),
                isSelected: isSelected,
                onTap: () {
                  if (!isSelected) {
                    notifier.updateConfig(config.copyWith(themePreset: preset));
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Font Family
        Text(
          'Font Family',
          style: TextStyle(
            fontSize: AppTypography.sm,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFontChip('Merriweather', 'Merriweather', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Literata', 'Literata', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Atkinson', 'Atkinson Hyperlegible', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Inter', 'Inter', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Lora', 'Lora', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Fira Code', 'Fira Code', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Outfit', 'Outfit', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Playfair', 'Playfair Display', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Nunito', 'Nunito', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Comic Neue', 'Comic Neue', config, notifier),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Font Weight
        Text(
          'Font Weight',
          style: TextStyle(
            fontSize: AppTypography.sm,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFontWeightChip('Light', FontWeight.w300, config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontWeightChip('Normal', FontWeight.normal, config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontWeightChip('Medium', FontWeight.w500, config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontWeightChip('Bold', FontWeight.bold, config, notifier),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Text Alignment
        Text(
          'Text Alignment',
          style: TextStyle(
            fontSize: AppTypography.sm,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
              value: TextAlign.left,
              label: Text('Left'),
              icon: Icon(Icons.format_align_left),
            ),
            ButtonSegment(
              value: TextAlign.center,
              label: Text('Center'),
              icon: Icon(Icons.format_align_center),
            ),
            ButtonSegment(
              value: TextAlign.justify,
              label: Text('Justify'),
              icon: Icon(Icons.format_align_justify),
            ),
          ],
          selected: {config.textAlignment},
          onSelectionChanged: (Set<TextAlign> newSelection) {
            notifier.updateConfig(config.copyWith(textAlignment: newSelection.first));
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Font Size
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: TextStyle(
                fontSize: AppTypography.sm,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.format_size, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8.0,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  thumbColor: colorScheme.primary,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  showValueIndicator: ShowValueIndicator.onDrag,
                ),
                child: Slider(
                  value: config.fontSize,
                  min: 12.0,
                  max: 32.0,
                  divisions: 20,
                  label: '${config.fontSize.toInt()} px',
                  onChanged: (value) {
                    notifier.updateConfig(config.copyWith(fontSize: value));
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.format_size, size: 24, color: colorScheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Line Spacing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Line Spacing',
              style: TextStyle(
                fontSize: AppTypography.sm,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.density_small, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8.0,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  thumbColor: colorScheme.primary,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  showValueIndicator: ShowValueIndicator.onDrag,
                ),
                child: Slider(
                  value: config.lineSpacing,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  label: '${config.lineSpacing.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    notifier.updateConfig(
                      config.copyWith(
                        lineSpacing: double.parse(value.toStringAsFixed(1)),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.format_line_spacing, size: 24, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ],
    );
  }

  Widget _buildFontChip(
    String label,
    String? fontFamily,
    ReaderConfig config,
    ReaderController notifier,
  ) {
    final isSelected = config.fontFamily == (fontFamily ?? 'Inter');
    return ExpressiveChip(
      label: label,
      fontFamily: fontFamily,
      isSelected: isSelected,
      onTap: () {
        if (!isSelected) {
          notifier.updateConfig(config.copyWith(fontFamily: fontFamily ?? 'Inter'));
        }
      },
    );
  }

  Widget _buildFontWeightChip(
    String label,
    FontWeight weight,
    ReaderConfig config,
    ReaderController notifier,
  ) {
    final isSelected = config.fontWeight == weight;
    return ExpressiveChip(
      label: label,
      fontFamily: config.fontFamily,
      isSelected: isSelected,
      onTap: () {
        if (!isSelected) {
          notifier.updateConfig(config.copyWith(fontWeight: weight));
        }
      },
    );
  }
}
