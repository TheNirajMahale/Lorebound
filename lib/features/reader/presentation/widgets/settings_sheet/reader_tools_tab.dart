import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
import '../../../domain/models/reader_config.dart';
import '../../providers/reader_controller.dart';

class ReaderToolsTab extends ConsumerWidget {
  const ReaderToolsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = ref.watch(readerControllerProvider).config;
    final notifier = ref.read(readerControllerProvider.notifier);

    String speedLabel(double speed) {
      if (speed <= 25) return 'Slow';
      if (speed <= 55) return 'Normal';
      if (speed <= 90) return 'Fast';
      return 'Turbo';
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (config.mode == ReaderMode.scroll)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.speed_rounded,
                    color: config.autoScrollEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Auto-Scroll'),
                  subtitle: Text(
                    config.autoScrollEnabled
                        ? 'Hands-free reading • ${speedLabel(config.autoScrollSpeed)} (${config.autoScrollSpeed.toInt()} px/s)'
                        : 'Continuous hands-free reading',
                  ),
                  trailing: Switch(
                    value: config.autoScrollEnabled,
                    onChanged: (val) {
                      notifier.updateConfig(config.copyWith(autoScrollEnabled: val));
                    },
                  ),
                ),
                if (config.autoScrollEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scroll Speed',
                              style: TextStyle(
                                fontSize: AppTypography.sm,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${config.autoScrollSpeed.toInt()} px/s',
                              style: TextStyle(
                                fontSize: AppTypography.xs,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: config.autoScrollSpeed.clamp(15.0, 120.0),
                          min: 15.0,
                          max: 120.0,
                          divisions: 21,
                          label: '${config.autoScrollSpeed.toInt()} px/s',
                          onChanged: (val) {
                            notifier.updateConfig(
                              config.copyWith(autoScrollSpeed: val.roundToDouble()),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSpeedChip('Slow (20)', 20.0, config, notifier),
                            _buildSpeedChip('Normal (45)', 45.0, config, notifier),
                            _buildSpeedChip('Fast (75)', 75.0, config, notifier),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            leading: Icon(
              Icons.speed_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            title: Text(
              'Auto-Scroll',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            subtitle: Text(
              'Only available in continuous vertical scroll mode (Layout tab)',
              style: TextStyle(
                fontSize: AppTypography.xs,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          leading: const Icon(Icons.auto_awesome_rounded),
          title: const Text('RuneGlass Reading Assistant'),
          subtitle: const Text('Bionic reading & dictionary lookup (Phase 7)'),
          trailing: const Chip(label: Text('Phase 7')),
        ),
      ],
    );
  }

  Widget _buildSpeedChip(
    String label,
    double targetSpeed,
    ReaderConfig config,
    ReaderController notifier,
  ) {
    final isSelected = (config.autoScrollSpeed - targetSpeed).abs() < 5.0;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        notifier.updateConfig(config.copyWith(autoScrollSpeed: targetSpeed));
      },
    );
  }
}
