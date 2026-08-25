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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFilterTab(context, colorScheme),
                  _buildSortTab(context, colorScheme),
                  _buildDisplayTab(context, colorScheme),
                ],
              ),
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
    bool? checkboxValue;
    switch (state) {
      case FilterState.include:
        checkboxValue = true;
        break;
      case FilterState.exclude:
        checkboxValue = null;
        break;
      case FilterState.unselected:
        checkboxValue = false;
        break;
    }

    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      tristate: true,
      value: checkboxValue,
      onChanged: (bool? newValue) {
        if (newValue == true) {
          onChanged(FilterState.include);
        } else if (newValue == null) {
          onChanged(FilterState.exclude);
        } else {
          onChanged(FilterState.unselected);
        }
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
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
        RadioGroup<SortType>(
          groupValue: prefs.sortType,
          onChanged: (val) => val != null ? notifier.updateSortType(val) : null,
          child: Column(
            children: [
              RadioListTile<SortType>(
                title: const Text('Title'),
                value: SortType.title,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<SortType>(
                title: const Text('Last Read'),
                value: SortType.lastRead,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<SortType>(
                title: const Text('Date Added'),
                value: SortType.dateAdded,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
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
        RadioGroup<DisplayMode>(
          groupValue: prefs.displayMode,
          onChanged: (val) => val != null ? notifier.updateDisplayMode(val) : null,
          child: Column(
            children: [
              RadioListTile<DisplayMode>(
                title: const Text('Comfortable Grid'),
                subtitle: const Text('Larger covers, 2 per row'),
                value: DisplayMode.comfortableGrid,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<DisplayMode>(
                title: const Text('Compact Grid'),
                subtitle: const Text('Smaller covers, 3 per row'),
                value: DisplayMode.compactGrid,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<DisplayMode>(
                title: const Text('List'),
                subtitle: const Text('Detailed view with reading progress'),
                value: DisplayMode.list,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
