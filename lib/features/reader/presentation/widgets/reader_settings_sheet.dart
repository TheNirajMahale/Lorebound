import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
import 'package:lorebound/core/widgets/expressive_chip.dart';
import '../providers/reader_controller.dart';
import '../../domain/models/reader_config.dart';

class ReaderSettingsSheet extends ConsumerStatefulWidget {
  final List<String> chapters;
  final int currentChapterIndex;
  final ValueChanged<int>? onChapterSelected;
  final String bookTitle;
  final String? author;

  const ReaderSettingsSheet({
    super.key,
    this.chapters = const [],
    this.currentChapterIndex = 0,
    this.onChapterSelected,
    this.bookTitle = '',
    this.author,
  });

  @override
  ConsumerState<ReaderSettingsSheet> createState() =>
      _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends ConsumerState<ReaderSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(readerControllerProvider).config;
    final notifier = ref.read(readerControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final tabOrder = ref.watch(readerTabOrderProvider);

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return TabBar(
                    controller: _tabController,
                    indicator:
                        const BoxDecoration(), // Removes the underline completely
                    dividerColor: Colors.transparent,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: TextStyle(
                      fontSize: AppTypography.xs,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTypography.fontFamily,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: AppTypography.xs,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTypography.fontFamily,
                    ),
                    tabs: tabOrder.map((tabName) {
                      final isSelected = _tabController.index == tabOrder.indexOf(tabName);
                      IconData selectedIcon;
                      IconData unselectedIcon;
                      if (tabName == 'Navigation') {
                        selectedIcon = Icons.menu_book;
                        unselectedIcon = Icons.menu_book_outlined;
                      } else if (tabName == 'Appearance') {
                        selectedIcon = Icons.palette;
                        unselectedIcon = Icons.palette_outlined;
                      } else {
                        selectedIcon = Icons.build;
                        unselectedIcon = Icons.build_outlined;
                      }
                      
                      return Tab(
                        icon: Icon(
                          isSelected ? selectedIcon : unselectedIcon,
                          size: 20,
                        ),
                        text: tabName,
                        height: 48,
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Main Tab Content Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: tabOrder.map((tabName) {
                  if (tabName == 'Navigation') {
                    return _buildNavigationTab(context, colorScheme);
                  } else if (tabName == 'Appearance') {
                    return _buildAppearanceTab(context, colorScheme, config, notifier);
                  } else {
                    return _buildToolsTab(context, colorScheme);
                  }
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNavigationTab(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.bookTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.md,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.author != null && widget.author!.isNotEmpty)
                  Text(
                    widget.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.xs,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.chapters.length} Chapters',
                  style: TextStyle(
                    fontSize: AppTypography.xs,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        Expanded(
          child: widget.chapters.isEmpty
              ? Center(
                  child: Text(
                    'No chapters found.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.chapters.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  itemBuilder: (context, index) {
                    final isCurrent = index == widget.currentChapterIndex;
                    final title = widget.chapters[index];

                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      selected: isCurrent,
                      selectedTileColor: colorScheme.secondaryContainer,
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        title.isEmpty ? 'Chapter ${index + 1}' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      trailing: null,
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onChapterSelected?.call(index);
                      },
                    ));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppearanceTab(
    BuildContext context,
    ColorScheme colorScheme,
    ReaderConfig config,
    ReaderController notifier,
  ) {
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
            notifier.updateConfig(config.copyWith(mode: newSelection.first));
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
              _buildFontChip('Default (Sans)', 'Inter', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Serif', 'Lora', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Monospace', 'Fira Code', config, notifier),
              const SizedBox(width: AppSpacing.sm),
              _buildFontChip('Outfit', 'Outfit', config, notifier),
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

  Widget _buildToolsTab(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          leading: const Icon(Icons.speed_rounded),
          title: const Text('Auto-Scroll'),
          subtitle: const Text('Continuous hands-free reading'),
          trailing: Switch(
            value: false,
            onChanged: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auto-Scroll will be available in next update'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          leading: const Icon(Icons.search_rounded),
          title: const Text('Search in Book'),
          subtitle: const Text('Find keywords across all chapters'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search in Book coming soon'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          leading: const Icon(Icons.auto_awesome_rounded),
          title: const Text('RuneGlass Reading Assistant'),
          subtitle: const Text('Bionic reading & dictionary lookup (Phase 6)'),
          trailing: const Chip(label: Text('Phase 6')),
        ),
      ],
    );
  }
}
