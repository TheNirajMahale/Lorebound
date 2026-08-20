import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final Set<int> _selectedBookIds = {};
  bool get _isSelectionMode => _selectedBookIds.isNotEmpty;
  
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int bookId) {
    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId);
      } else {
        _selectedBookIds.add(bookId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedBookIds.clear();
    });
  }

  void _selectAll(List<int> allBookIds) {
    setState(() {
      _selectedBookIds.addAll(allBookIds);
    });
  }

  void _inverseSelection(List<int> allBookIds) {
    setState(() {
      final unselected = allBookIds.where((id) => !_selectedBookIds.contains(id)).toList();
      _selectedBookIds.clear();
      _selectedBookIds.addAll(unselected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(filteredLibraryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _isSelectionMode 
          ? _buildSelectionAppBar(context, colorScheme, libraryState.value?.map((b) => b.id).toList() ?? [])
          : _buildNormalAppBar(context),
      body: libraryState.when(
        data: (books) {
          if (books.isEmpty) {
            return _buildEmptyState(context, colorScheme);
          }
          final prefs = ref.watch(libraryPreferencesProvider);
          
          if (prefs.displayMode == DisplayMode.list) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return BookListTile(
                  book: book,
                  isSelected: _selectedBookIds.contains(book.id),
                  isSelectionMode: _isSelectionMode,
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(book.id);
                    } else {
                      context.push('/library/book/${book.id}');
                    }
                  },
                  onLongPress: () {
                    _toggleSelection(book.id);
                  },
                );
              },
            );
          }

          final crossAxisCount = prefs.displayMode == DisplayMode.compactGrid ? 3 : 2;
          final childAspectRatio = prefs.displayMode == DisplayMode.compactGrid ? 0.65 : 0.70;

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
              return BookCard(
                book: book,
                isSelected: _selectedBookIds.contains(book.id),
                isSelectionMode: _isSelectionMode,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(book.id);
                  } else {
                    context.push('/library/book/${book.id}');
                  }
                },
                onLongPress: () {
                  _toggleSelection(book.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
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
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar(context, colorScheme) : null,
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
              final prefs = ref.watch(libraryPreferencesProvider);
              final categoriesState = ref.watch(categoriesProvider);
              
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
                children: [
                  ExpressiveChip(
                    label: 'All',
                    isSelected: prefs.selectedCategoryId == null,
                    onTap: () => ref.read(libraryPreferencesProvider.notifier).updateSelectedCategoryId(null),
                  ),
                  ...categoriesState.when(
                    data: (categories) => categories.map((cat) => ExpressiveChip(
                      label: cat.name,
                      isSelected: prefs.selectedCategoryId == cat.id,
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
              backgroundColor: Colors.transparent,
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

  AppBar _buildSelectionAppBar(BuildContext context, ColorScheme colorScheme, List<int> allBookIds) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text('${_selectedBookIds.length} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select All',
          onPressed: () => _selectAll(allBookIds),
        ),
        IconButton(
          icon: const Icon(Icons.flip_to_back), // Inverse selection icon
          tooltip: 'Inverse Selection',
          onPressed: () => _inverseSelection(allBookIds),
        ),
      ],
    );
  }

  Widget _buildSelectionBottomBar(BuildContext context, ColorScheme colorScheme) {
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
                backgroundColor: Colors.transparent,
                builder: (context) => AssignCategorySheet(selectedBookIds: _selectedBookIds.toList()),
              ).then((_) => _clearSelection());
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Mark as read',
            onPressed: () {
              ref.read(libraryControllerProvider.notifier)
                  .bulkUpdateStatus(_selectedBookIds.toList(), 'READ');
              _clearSelection();
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility_off_outlined),
            tooltip: 'Mark as unread',
            onPressed: () {
              ref.read(libraryControllerProvider.notifier)
                  .bulkUpdateStatus(_selectedBookIds.toList(), 'WANT_TO_READ', chapter: 0);
              _clearSelection();
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
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final count = _selectedBookIds.length;
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

    if (confirm == true && mounted) {
      ref.read(libraryControllerProvider.notifier).bulkDeleteBooks(_selectedBookIds.toList(), deleteLocalFiles: deleteLocalFiles);
      _clearSelection();
    }
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
