import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reading_statistics.dart';

class LibraryCompletionFunnelCard extends StatelessWidget {
  final ReadingStatistics stats;

  const LibraryCompletionFunnelCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = stats.totalBooksInLibrary;

    final readingRatio = total > 0 ? (stats.booksReading / total) : 0.0;
    final completedRatio = total > 0 ? (stats.booksCompleted / total) : 0.0;
    final wantToReadRatio = total > 0 ? (stats.booksWantToRead / total) : 0.0;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Library Status Overview',
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
                Text(
                  '$total Books',
                  style: TextStyle(
                    fontSize: AppTypography.xs,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Distribution across your library statuses.',
              style: TextStyle(
                fontSize: AppTypography.xs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Segmented Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (readingRatio > 0)
                      Expanded(
                        flex: (readingRatio * 100).toInt().clamp(1, 100),
                        child: Container(color: colorScheme.primary),
                      ),
                    if (completedRatio > 0)
                      Expanded(
                        flex: (completedRatio * 100).toInt().clamp(1, 100),
                        child: Container(color: Colors.green.shade500),
                      ),
                    if (wantToReadRatio > 0)
                      Expanded(
                        flex: (wantToReadRatio * 100).toInt().clamp(1, 100),
                        child: Container(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    if (total == 0)
                      Expanded(
                        child: Container(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Legend / Counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  label: 'Reading',
                  count: stats.booksReading,
                  color: colorScheme.primary,
                  colorScheme: colorScheme,
                ),
                _buildStatusItem(
                  label: 'Completed',
                  count: stats.booksCompleted,
                  color: Colors.green.shade500,
                  colorScheme: colorScheme,
                ),
                _buildStatusItem(
                  label: 'Want to Read',
                  count: stats.booksWantToRead,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required String label,
    required int count,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: AppTypography.sm,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
