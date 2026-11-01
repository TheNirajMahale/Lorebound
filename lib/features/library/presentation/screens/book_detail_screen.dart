import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/repositories/local_book_repository.dart';
import '../providers/library_controller.dart';
import '../providers/book_chapters_provider.dart';
import '../widgets/assign_category_sheet.dart';
import '../widgets/book_search_sheet.dart';
import '../../domain/models/book.dart';
import '../../../settings/domain/models/chapter_swipe_config.dart';
import '../../../settings/presentation/providers/chapter_swipe_provider.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

class BookDetailScreen extends ConsumerWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryControllerProvider);
    final swipeConfig = ref.watch(chapterSwipeProvider);
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BackButton(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'Search in book',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BookSearchSheet(book: book),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'change_category') {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          builder: (context) => AssignCategorySheet(selectedBookIds: [bookId]),
                        );
                      } else if (value == 'upload_vault') {
                        await _handleUpload(context, ref, book);
                      } else if (value == 'download_vault') {
                        await _handleDownload(context, ref, book);
                      } else if (value == 'remove_download') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Download?'),
                            content: const Text(
                              'The local EPUB file and reading cache will be deleted to free device storage. The book remains in your cloud library and can be re-downloaded anytime.',
                            ),
                            actions: [
                              TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => context.pop(true),
                                child: const Text('Remove Download'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await ref.read(libraryControllerProvider.notifier).removeDownload(bookId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Local download removed. Preserved in cloud.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } else if (value == 'delete') {
                        final String title = book.isSynced
                            ? 'Delete from Library & Cloud?'
                            : (book.isCloudOnly ? 'Delete from Cloud?' : 'Delete Book?');
                        final String message = book.isSynced
                            ? 'This will delete the local file and permanently remove the book from your LoreKeeper cloud account.'
                            : (book.isCloudOnly
                                ? 'This will permanently remove the book from your LoreKeeper cloud account.'
                                : 'This will permanently remove the book from your device. This cannot be undone.');

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(title),
                            content: Text(message),
                            actions: [
                              TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                onPressed: () => context.pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          ref.read(libraryControllerProvider.notifier).deleteBook(
                                bookId,
                                deleteFromCloud: book.backendId != null,
                              );
                          context.pop(); // Go back to library
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change_category',
                        child: Text('Change Category'),
                      ),
                      if (book.isLocalOnly)
                        const PopupMenuItem(
                          value: 'upload_vault',
                          child: Text('Backup to Cloud Vault'),
                        ),
                      if (book.isCloudOnly)
                        const PopupMenuItem(
                          value: 'download_vault',
                          child: Text('Download to Device'),
                        ),
                      if (book.isSynced)
                        const PopupMenuItem(
                          value: 'remove_download',
                          child: Text('Remove Download (Keep in Cloud)'),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          book.isSynced
                              ? 'Delete from Library & Cloud'
                              : (book.isCloudOnly ? 'Delete from Cloud' : 'Delete Book'),
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.paddingOf(context).bottom,
        color: colorScheme.surface,
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
                      image: book.coverPath != null && book.coverPath!.isNotEmpty && File(book.coverPath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(book.coverPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: book.coverPath == null || book.coverPath!.isEmpty || !File(book.coverPath!).existsSync()
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
                      onPressed: book.filePath != null
                          ? () {
                              context.push(
                                '/reader?bookId=${book.id}&filePath=${Uri.encodeComponent(book.filePath!)}',
                              );
                            }
                          : () => _handleDownload(context, ref, book),
                      icon: Icon(book.isCloudOnly
                          ? Icons.cloud_download_outlined
                          : (isUnread ? Icons.play_arrow : Icons.play_circle_fill)),
                      label: Text(book.isCloudOnly
                          ? 'Download to Read'
                          : (isUnread ? 'Read' : 'Resume')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (book.isCloudOnly)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download to Device',
                      onPressed: () => _handleDownload(context, ref, book),
                    )
                  else if (book.isLocalOnly)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.cloud_upload_outlined),
                      tooltip: 'Backup to Cloud Vault',
                      onPressed: () => _handleUpload(context, ref, book),
                    )
                  else
                    IconButton.filledTonal(
                      icon: const Icon(Icons.cloud_done_outlined),
                      tooltip: 'Synced with Cloud Vault',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This book is safely backed up and synced with your LoreKeeper vault.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
            _buildChapterList(context, ref, book, book.cachedChapters!, colorScheme, swipeConfig)
          else if (book.filePath != null)
            Consumer(
              builder: (context, consumerRef, child) {
                final chaptersAsync = consumerRef.watch(bookChaptersProvider(book.filePath!));
                
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
                      child: Text('Error loading chapters: $e', style: TextStyle(color: colorScheme.error)),
                    ),
                  ),
                  data: (titles) => _buildChapterList(context, consumerRef, book, titles, colorScheme, swipeConfig),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
      ),
    );
  }

  Widget _buildChapterList(
    BuildContext context, 
    WidgetRef ref,
    Book book, 
    List<String> titles, 
    ColorScheme colorScheme,
    ChapterSwipeConfig swipeConfig,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final isRead = index < book.currentChapter;
          final isCurrent = index == book.currentChapter;
          
          Widget buildBackground(SwipeAction action, Alignment alignment) {
            return Container(
              color: action.color(colorScheme),
              alignment: alignment,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Icon(action.icon, color: colorScheme.onPrimary),
            );
          }

          return Dismissible(
            key: ValueKey('${book.id}_chapter_$index'),
            dismissThresholds: const {
              DismissDirection.startToEnd: 0.35,
              DismissDirection.endToStart: 0.35,
            },
            background: buildBackground(swipeConfig.swipeLeft, Alignment.centerLeft),
            secondaryBackground: buildBackground(swipeConfig.swipeRight, Alignment.centerRight),
            confirmDismiss: (direction) async {
              final action = direction == DismissDirection.startToEnd 
                  ? swipeConfig.swipeLeft 
                  : swipeConfig.swipeRight;
                  
              if (action == SwipeAction.none) return false;
              
              // Execute the update asynchronously so the snap-back animation is never interrupted
              Future.microtask(() async {
                if (action == SwipeAction.markAsRead) {
                  await ref.read(localBookRepositoryProvider).updateBookProgress(book.id, index + 1, '0.0');
                  ref.read(libraryControllerProvider.notifier).refresh();
                } else if (action == SwipeAction.markAsUnread) {
                  await ref.read(localBookRepositoryProvider).updateBookProgress(book.id, index, '0.0');
                  ref.read(libraryControllerProvider.notifier).refresh();
                }
              });
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${action.label} - Chapter ${index + 1}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
              
              // Immediately return false so Dismissible cleanly springs back to normal chapter title
              return false;
            },
            child: ListTile(
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
            ),
          );
        },
        childCount: titles.length,
      ),
    );
  }

  Future<void> _handleUpload(BuildContext context, WidgetRef ref, Book book) async {
    final authState = ref.read(sessionControllerProvider).value;
    if (authState == null || !authState.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('LoreKeeper Account Required'),
          content: const Text(
            'To backup books to your cloud vault, sign in or create a free LoreKeeper account.',
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                ctx.pop();
                context.push('/auth');
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onInverseSurface),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Uploading "${book.title}" to Vault...')),
          ],
        ),
        duration: const Duration(minutes: 2),
      ),
    );

    final success = await ref.read(libraryControllerProvider.notifier).uploadBook(book.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" backed up to Cloud Vault!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload book to vault. Please check server connection.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref, Book book) async {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onInverseSurface),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Downloading "${book.title}" from Vault...')),
          ],
        ),
        duration: const Duration(minutes: 2),
      ),
    );

    final success = await ref.read(libraryControllerProvider.notifier).downloadBook(book.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" downloaded! Ready to read offline.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Ensure backend server is reachable.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
