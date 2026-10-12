import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reading_statistics.dart';

class StalledBooksShelfCard extends StatelessWidget {
  final List<StalledBook> stalledBooks;
  final ValueChanged<int> onMoveToOnHold;

  const StalledBooksShelfCard({
    super.key,
    required this.stalledBooks,
    required this.onMoveToOnHold,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (stalledBooks.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green.shade400,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Stalled Books',
                      style: TextStyle(
                        fontSize: AppTypography.sm,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your active reading shelf is in sync. Keep up the momentum!',
                      style: TextStyle(
                        fontSize: AppTypography.xs,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: Colors.amber.shade700.withValues(alpha: 0.35),
        ),
      ),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 20,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '1-Week Stall Tracking',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.md,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade700.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${stalledBooks.length} Stalled',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Books untouched for 7+ days. Resume where you paused or archive to keep your active shelf clean.',
              style: TextStyle(
                fontSize: AppTypography.xs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...stalledBooks.map((stalled) => _buildStalledBookItem(context, stalled, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildStalledBookItem(
    BuildContext context,
    StalledBook stalled,
    ColorScheme colorScheme,
  ) {
    final book = stalled.book;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 68,
              child: (stalled.coverPath != null &&
                      stalled.coverPath!.isNotEmpty &&
                      File(stalled.coverPath!).existsSync())
                  ? Image.file(File(stalled.coverPath!), fit: BoxFit.cover)
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.book_outlined,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Info & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.pause_circle_outline, size: 12, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Paused at Ch. ${stalled.pausedChapter}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (stalled.totalChapters > 0)
                      Text(
                        ' / ${stalled.totalChapters}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Untouched for ${stalled.daysStalled} days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                // Action Buttons with responsive Wrap layout
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        minimumSize: const Size(0, 30),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        context.push(
                          '/reader/${book.id}',
                          extra: {
                            'filePath': book.filePath,
                            'initialChapter': stalled.pausedChapter,
                          },
                        );
                      },
                      child: const Text('Resume Reading'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 30),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => onMoveToOnHold(book.id),
                      child: const Text('Move to On-Hold'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
