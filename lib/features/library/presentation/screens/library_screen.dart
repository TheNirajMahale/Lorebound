import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_controller.dart';
import '../widgets/library_filter_sheet.dart';
import '../widgets/book_card.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/category_management_dialog.dart';
import '../widgets/assign_category_sheet.dart';
import '../../../../core/widgets/expressive_chip.dart';
import '../providers/library_preferences_provider.dart';
import '../providers/library_categories_provider.dart';
import '../../data/services/epub_import_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/library_selection_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = ref.watch(librarySelectionProvider.select((s) => s.isNotEmpty));
    final libraryState = ref.watch(filteredLibraryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: isSelectionMode 
          ? SelectionAppBar(allBookIds: libraryState.value?.map((b) => b.id).toList() ?? [])
          : _buildNormalAppBar(context),
      body: libraryState.when(
        data: (books) {
          if (books.isEmpty) {
            return _buildEmptyState(context, colorScheme);
          }
          final displayMode = ref.watch(libraryPreferencesProvider.select((p) => p.displayMode));
          
          if (displayMode == DisplayMode.list) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return BookListTile(book: book);
              },
            );
          }

          final crossAxisCount = displayMode == DisplayMode.compactGrid ? 3 : 2;
          final childAspectRatio = displayMode == DisplayMode.compactGrid ? 0.65 : 0.70;

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(book: book);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: isSelectionMode ? null : FloatingActionButton(
        onPressed: () async {
          bool dialogShown = false;
          final service = ref.read(epubImportServiceProvider);
          final success = await service.pickAndImportEpub(
            onStartImporting: (count) {
              dialogShown = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: AppSpacing.md),
                      Text('Importing $count book${count > 1 ? 's' : ''}...'),
                    ],
                  ),
                ),
              );
            },
          );
          
          if (!context.mounted) return;
          if (dialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (success) {
            ref.read(libraryControllerProvider.notifier).refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: isSelectionMode ? const SelectionBottomBar() : null,
    );
  }

  AppBar _buildNormalAppBar(BuildContext context) {
    if (_isSearchActive) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearchActive = false;
              _searchController.clear();
              ref.read(libraryPreferencesProvider.notifier).updateSearchQuery('');
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search library...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(libraryPreferencesProvider.notifier).updateSearchQuery(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(libraryPreferencesProvider.notifier).updateSearchQuery('');
              },
            ),
        ],
      );
    }

    return AppBar(
      title: const Text('Library'),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: SizedBox(
          height: 56.0,
          child: Consumer(
            builder: (context, ref, child) {
              final categoryId = ref.watch(libraryPreferencesProvider.select((p) => p.selectedCategoryId));
              final categoriesState = ref.watch(categoriesProvider);
              
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
                children: [
                  ExpressiveChip(
                    label: 'All',
                    isSelected: categoryId == null,
                    onTap: () => ref.read(libraryPreferencesProvider.notifier).updateSelectedCategoryId(null),
                  ),
                  ...categoriesState.when(
                    data: (categories) => categories.map((cat) => ExpressiveChip(
                      label: cat.name,
                      isSelected: categoryId == cat.id,
                      onTap: () => ref.read(libraryPreferencesProvider.notifier).updateSelectedCategoryId(cat.id),
                    )).toList(),
                    loading: () => const [Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))],
                    error: (_, __) => const [],
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearchActive = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: false,
              showDragHandle: true,
              builder: (context) => const LibraryFilterSheet(),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'new_category') {
              showDialog(
                context: context,
                builder: (context) => const CategoryManagementDialog(),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_category',
              child: Text('New Category'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_bookmark_outlined, size: 80, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your library is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap the + button to import an EPUB',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class SelectionAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final List<int> allBookIds;
  
  const SelectionAppBar({super.key, required this.allBookIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(librarySelectionProvider.select((s) => s.length));
    
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => ref.read(librarySelectionProvider.notifier).clearSelection(),
      ),
      title: Text('$selectedCount selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select All',
          onPressed: () => ref.read(librarySelectionProvider.notifier).selectAll(allBookIds),
        ),
        IconButton(
          icon: const Icon(Icons.flip_to_back),
          tooltip: 'Inverse Selection',
          onPressed: () => ref.read(librarySelectionProvider.notifier).inverseSelection(allBookIds),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SelectionBottomBar extends ConsumerWidget {
  const SelectionBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedBookIds = ref.watch(librarySelectionProvider);

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Change category',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (context) => AssignCategorySheet(selectedBookIds: selectedBookIds.toList()),
              ).then((_) => ref.read(librarySelectionProvider.notifier).clearSelection());
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Mark as read',
            onPressed: () {
              ref.read(libraryControllerProvider.notifier)
                  .bulkUpdateStatus(selectedBookIds.toList(), 'READ');
              ref.read(librarySelectionProvider.notifier).clearSelection();
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility_off_outlined),
            tooltip: 'Mark as unread',
            onPressed: () {
              ref.read(libraryControllerProvider.notifier)
                  .bulkUpdateStatus(selectedBookIds.toList(), 'WANT_TO_READ', chapter: 0);
              ref.read(librarySelectionProvider.notifier).clearSelection();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download',
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () {
              _showDeleteConfirmationDialog(context, ref, selectedBookIds.toList());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, List<int> selectedIds) async {
    final count = selectedIds.length;
    bool deleteLocalFiles = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Delete $count books?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This will remove the books from your library. This action cannot be undone.'),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Delete from local file system also'),
                  value: deleteLocalFiles,
                  onChanged: (value) {
                    setState(() {
                      deleteLocalFiles = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        }
      ),
    );

    if (confirm == true && context.mounted) {
      ref.read(libraryControllerProvider.notifier).bulkDeleteBooks(selectedIds, deleteLocalFiles: deleteLocalFiles);
      ref.read(librarySelectionProvider.notifier).clearSelection();
    }
  }
}
