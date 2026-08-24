import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/book.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/library_selection_provider.dart';

class BookListTile extends ConsumerWidget {
  final Book book;

  const BookListTile({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isSelected = ref.watch(librarySelectionProvider.select((s) => s.contains(book.id)));
    final isSelectionMode = ref.watch(librarySelectionProvider.select((s) => s.isNotEmpty));
    
    // Calculate progress safely
    double progressValue = 0.0;
    if (book.totalChapters > 0) {
      if (book.status == 'READ') {
        progressValue = 1.0;
      } else {
        progressValue = book.currentChapter / book.totalChapters;
      }
    }
    
    void handleTap() {
      if (isSelectionMode) {
        ref.read(librarySelectionProvider.notifier).toggleSelection(book.id);
      } else {
        context.push('/library/book/${book.id}');
      }
    }

    void handleLongPress() {
      ref.read(librarySelectionProvider.notifier).toggleSelection(book.id);
    }

    return InkWell(
      onTap: handleTap,
      onLongPress: handleLongPress,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected 
            ? Border.all(color: colorScheme.primary, width: 3)
            : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              width: 60,
              height: 90,
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
                  ? Icon(Icons.menu_book, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.author != null && book.author!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      book.author!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 4,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressValue == 1.0 ? Colors.green : colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${(progressValue * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Selection Checkbox
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) => handleTap(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
