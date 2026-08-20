import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/library_controller.dart';
import '../providers/book_chapters_provider.dart';
import '../widgets/assign_category_sheet.dart';
import '../../domain/models/book.dart';

class BookDetailScreen extends ConsumerWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Find the book
    final Book? book = libraryState.value?.cast<Book?>().firstWhere(
      (b) => b?.id == bookId,
      orElse: () => null,
    );

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Not Found')),
        body: const Center(child: Text('This book may have been deleted.')),
      );
    }

    final bool isUnread = book.currentChapter == 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'change_category') {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AssignCategorySheet(selectedBookIds: [bookId]),
                );
              } else if (value == 'delete') {
                bool deleteLocalFiles = true;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text('Delete Book?'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('This will remove the book from your library. Cannot be undone.'),
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
                          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                            onPressed: () => context.pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    }
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  ref.read(libraryControllerProvider.notifier).deleteBook(bookId, deleteLocalFiles: deleteLocalFiles);
                  context.pop(); // Go back to library
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_category',
                child: Text('Change Category'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Book', style: TextStyle(color: colorScheme.error)),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image
                  Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      image: book.coverPath != null && book.coverPath!.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(book.coverPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: book.coverPath == null || book.coverPath!.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                book.title,
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: AppTypography.xs,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: AppTypography.lg,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          book.author ?? 'Unknown Author',
                          style: TextStyle(
                            fontSize: AppTypography.md,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.library_books, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${book.totalChapters} chapters',
                              style: TextStyle(
                                fontSize: AppTypography.sm,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              book.status.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: AppTypography.sm,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (book.filePath != null) {
                           context.push('/reader?bookId=${book.id}&filePath=${Uri.encodeComponent(book.filePath!)}');
                        }
                      },
                      icon: Icon(isUnread ? Icons.play_arrow : Icons.play_circle_fill),
                      label: Text(isUnread ? 'Read' : 'Resume'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.download),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          if (book.summary != null && book.summary!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  book.summary!,
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: Divider(height: 32),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Chapters',
                style: TextStyle(
                  fontSize: AppTypography.md,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (book.cachedChapters != null && book.cachedChapters!.isNotEmpty)
            _buildChapterList(context, book, book.cachedChapters!, colorScheme)
          else if (book.filePath != null)
            Consumer(
              builder: (context, ref, child) {
                final chaptersAsync = ref.watch(bookChaptersProvider(book.filePath!));
                
                return chaptersAsync.when(
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ListTile(
                          title: Text(
                            'Loading Chapter ${index + 1}...',
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        );
                      },
                      childCount: book.totalChapters > 0 ? book.totalChapters : 1,
                    ),
                  ),
                  error: (e, st) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('Error loading chapters: $e', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  data: (titles) => _buildChapterList(context, book, titles, colorScheme),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChapterList(BuildContext context, Book book, List<String> titles, ColorScheme colorScheme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final isRead = index < book.currentChapter;
          final isCurrent = index == book.currentChapter;

          return ListTile(
            title: Text(
              titles[index],
              style: TextStyle(
                color: isRead 
                    ? colorScheme.onSurface.withValues(alpha: 0.5)
                    : colorScheme.onSurface,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isRead ? Icon(Icons.check, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)) : null,
            onTap: () {
                if (book.filePath != null) {
                  context.push('/reader?bookId=${book.id}&chapter=$index&filePath=${Uri.encodeComponent(book.filePath!)}');
                }
            },
          );
        },
        childCount: titles.length,
      ),
    );
  }
}
