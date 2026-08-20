import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
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
  ConsumerState<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
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
    final readerState = ref.watch(readerControllerProvider);
    final config = readerState.config;
    final notifier = ref.read(readerControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: SafeArea(
        top: false,
        child: Column(
          children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

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
                  indicator: const BoxDecoration(), // Removes the underline completely
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
                  tabs: [
                    Tab(
                      icon: Icon(
                        _tabController.index == 0
                            ? Icons.menu_book
                            : Icons.menu_book_outlined,
                        size: 20,
                      ),
                      text: 'Navigation',
                      height: 48,
                    ),
                    Tab(
                      icon: Icon(
                        _tabController.index == 1
                            ? Icons.palette
                            : Icons.palette_outlined,
                        size: 20,
                      ),
                      text: 'Appearance',
                      height: 48,
                    ),
                    Tab(
                      icon: Icon(
                        _tabController.index == 2
                            ? Icons.build
                            : Icons.build_outlined,
                        size: 20,
                      ),
                      text: 'Tools',
                      height: 48,
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Main Tab Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Navigation
                _buildNavigationTab(context, colorScheme),

                // Tab 2: Appearance
                _buildAppearanceTab(context, colorScheme, config, notifier),

                // Tab 3: Tools
                _buildToolsTab(context, colorScheme),
              ],
            ),
          ),
        ],
      ),
    )));
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

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      selected: isCurrent,
                      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        title.isEmpty ? 'Chapter ${index + 1}' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(
                              Icons.bookmark_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onChapterSelected?.call(index);
                      },
                    );
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
              value: ReaderMode.paginated,
              label: Text('Paginated'),
              icon: Icon(Icons.menu_book),
            ),
            ButtonSegment(
              value: ReaderMode.scroll,
              label: Text('Vertical Scroll'),
              icon: Icon(Icons.swap_vert),
            ),
          ],
          selected: {config.mode},
          onSelectionChanged: (Set<ReaderMode> newSelection) {
            notifier.updateConfig(
              config.copyWith(mode: newSelection.first),
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
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(preset.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      notifier.updateConfig(
                        config.copyWith(themePreset: preset),
                      );
                    }
                  },
                ),
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
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _buildFontChip('Default (Sans)', null, config, notifier),
            _buildFontChip('Serif', 'serif', config, notifier),
            _buildFontChip('Monospace', 'monospace', config, notifier),
          ],
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
            Text(
              '${config.fontSize.toInt()} px',
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: config.fontSize > 12
                  ? () => notifier.updateConfig(
                        config.copyWith(fontSize: config.fontSize - 1),
                      )
                  : null,
            ),
            Expanded(
              child: Slider(
                value: config.fontSize,
                min: 12.0,
                max: 32.0,
                divisions: 20,
                label: '${config.fontSize.toInt()}',
                onChanged: (value) {
                  notifier.updateConfig(config.copyWith(fontSize: value));
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: config.fontSize < 32
                  ? () => notifier.updateConfig(
                        config.copyWith(fontSize: config.fontSize + 1),
                      )
                  : null,
            ),
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
            Text(
              '${config.lineSpacing.toStringAsFixed(1)}x',
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: config.lineSpacing > 1.05
                  ? () => notifier.updateConfig(
                        config.copyWith(
                          lineSpacing: double.parse(
                            (config.lineSpacing - 0.1).clamp(1.0, 2.5).toStringAsFixed(1),
                          ),
                        ),
                      )
                  : null,
            ),
            Expanded(
              child: Slider(
                value: config.lineSpacing,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                label: config.lineSpacing.toStringAsFixed(1),
                onChanged: (value) {
                  notifier.updateConfig(
                    config.copyWith(
                      lineSpacing: double.parse(value.toStringAsFixed(1)),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: config.lineSpacing < 2.45
                  ? () => notifier.updateConfig(
                        config.copyWith(
                          lineSpacing: double.parse(
                            (config.lineSpacing + 0.1).clamp(1.0, 2.5).toStringAsFixed(1),
                          ),
                        ),
                      )
                  : null,
            ),
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
    final isSelected = config.fontFamily == fontFamily;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontFamily: fontFamily),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          notifier.updateConfig(
            config.copyWith(fontFamily: fontFamily),
          );
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
