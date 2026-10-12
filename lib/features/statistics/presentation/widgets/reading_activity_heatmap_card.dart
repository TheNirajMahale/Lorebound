import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reading_statistics.dart';

class ReadingActivityHeatmapCard extends StatelessWidget {
  final ReadingStatistics stats;

  const ReadingActivityHeatmapCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activity = stats.last30DaysActivity;

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
                  Icons.local_fire_department_rounded,
                  size: 22,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Reading Consistency',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 2),
                      Text(
                        '${stats.currentStreakDays}d streak',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Last 30 days activity',
                  style: TextStyle(
                    fontSize: AppTypography.xs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Best streak: ${stats.longestStreakDays} days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 30 days grid (6 columns x 5 rows or 10 cols x 3 rows)
            RepaintBoundary(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: activity.map((day) {
                  Color blockColor;
                  if (day.chaptersRead == 0) {
                    blockColor = colorScheme.outlineVariant.withValues(alpha: 0.2);
                  } else if (day.chaptersRead <= 2) {
                    blockColor = colorScheme.primary.withValues(alpha: 0.35);
                  } else if (day.chaptersRead <= 5) {
                    blockColor = colorScheme.primary.withValues(alpha: 0.65);
                  } else {
                    blockColor = colorScheme.primary;
                  }

                  final dateStr = '${day.date.day}/${day.date.month}';

                  return Tooltip(
                    message: '$dateStr: ${day.chaptersRead} chapters',
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: day.chaptersRead > 0
                              ? Colors.transparent
                              : colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Less', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                _buildLegendBox(colorScheme.outlineVariant.withValues(alpha: 0.2)),
                const SizedBox(width: 3),
                _buildLegendBox(colorScheme.primary.withValues(alpha: 0.35)),
                const SizedBox(width: 3),
                _buildLegendBox(colorScheme.primary.withValues(alpha: 0.65)),
                const SizedBox(width: 3),
                _buildLegendBox(colorScheme.primary),
                const SizedBox(width: 4),
                Text('More', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
