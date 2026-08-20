import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/library_controller.dart';
import '../widgets/library_filter_sheet.dart';
import '../widgets/book_card.dart';
import '../providers/library_preferences_provider.dart';
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
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
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
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
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
            onPressed: () {},
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
