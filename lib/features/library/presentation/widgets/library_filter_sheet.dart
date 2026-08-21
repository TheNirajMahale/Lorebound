import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/library_preferences_provider.dart';

class LibraryFilterSheet extends ConsumerStatefulWidget {
  const LibraryFilterSheet({super.key});

  @override
  ConsumerState<LibraryFilterSheet> createState() => _LibraryFilterSheetState();
}

class _LibraryFilterSheetState extends ConsumerState<LibraryFilterSheet> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(), // Remove underline
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Filter'),
                Tab(text: 'Sort'),
                Tab(text: 'Display'),
              ],
            ),
            const Divider(height: 1),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                switch (_tabController.index) {
                  case 0:
                    return _buildFilterTab(context, colorScheme);
                  case 1:
                    return _buildSortTab(context, colorScheme);
                  case 2:
                    return _buildDisplayTab(context, colorScheme);
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      );
  }

  Widget _buildFilterTab(BuildContext context, ColorScheme colorScheme) {
    final prefs = ref.watch(libraryPreferencesProvider);
    final notifier = ref.read(libraryPreferencesProvider.notifier);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            TextButton(
              onPressed: () => notifier.clearFilters(),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTriStateRow('Read', prefs.readFilter, notifier.updateReadFilter, colorScheme),
        _buildTriStateRow('Unread', prefs.unreadFilter, notifier.updateUnreadFilter, colorScheme),
        _buildTriStateRow('Started', prefs.startedFilter, notifier.updateStartedFilter, colorScheme),
      ],
    );
  }

  Widget _buildTriStateRow(String label, FilterState state, ValueChanged<FilterState> onChanged, ColorScheme colorScheme) {
    IconData icon;
    Color color;
    switch (state) {
      case FilterState.include:
        icon = Icons.check_box;
        color = colorScheme.primary;
        break;
      case FilterState.exclude:
        icon = Icons.indeterminate_check_box;
        color = colorScheme.error;
        break;
      case FilterState.unselected:
        icon = Icons.check_box_outline_blank;
        color = colorScheme.onSurfaceVariant;
        break;
    }

    return InkWell(
      onTap: () {
        if (state == FilterState.unselected) {
          onChanged(FilterState.include);
        } else if (state == FilterState.include) {
          onChanged(FilterState.exclude);
        } else {
          onChanged(FilterState.unselected);
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTab(BuildContext context, ColorScheme colorScheme) {
    final prefs = ref.watch(libraryPreferencesProvider);
    final notifier = ref.read(libraryPreferencesProvider.notifier);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            IconButton(
              icon: Icon(prefs.isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () => notifier.toggleSortDirection(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        RadioListTile<SortType>(
          title: const Text('Title'),
          value: SortType.title,
          groupValue: prefs.sortType,
          onChanged: (val) => val != null ? notifier.updateSortType(val) : null,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<SortType>(
          title: const Text('Last Read'),
          value: SortType.lastRead,
          groupValue: prefs.sortType,
          onChanged: (val) => val != null ? notifier.updateSortType(val) : null,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<SortType>(
          title: const Text('Date Added'),
          value: SortType.dateAdded,
          groupValue: prefs.sortType,
          onChanged: (val) => val != null ? notifier.updateSortType(val) : null,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDisplayTab(BuildContext context, ColorScheme colorScheme) {
    final prefs = ref.watch(libraryPreferencesProvider);
    final notifier = ref.read(libraryPreferencesProvider.notifier);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Display Mode', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        RadioListTile<DisplayMode>(
          title: const Text('Comfortable Grid'),
          subtitle: const Text('Larger covers, 2 per row'),
          value: DisplayMode.comfortableGrid,
          groupValue: prefs.displayMode,
          onChanged: (val) => val != null ? notifier.updateDisplayMode(val) : null,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<DisplayMode>(
          title: const Text('Compact Grid'),
          subtitle: const Text('Smaller covers, 3 per row'),
          value: DisplayMode.compactGrid,
          groupValue: prefs.displayMode,
          onChanged: (val) => val != null ? notifier.updateDisplayMode(val) : null,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<DisplayMode>(
          title: const Text('List'),
          subtitle: const Text('Detailed view with reading progress'),
          value: DisplayMode.list,
          groupValue: prefs.displayMode,
          onChanged: (val) => val != null ? notifier.updateDisplayMode(val) : null,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
