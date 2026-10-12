import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reading_statistics.dart';

class PeakReadingHoursCard extends StatelessWidget {
  final ReadingStatistics stats;

  const PeakReadingHoursCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hourly = stats.hourlyDistribution;

    int maxCount = 1;
    for (final h in hourly) {
      if (h.chapterCount > maxCount) {
        maxCount = h.chapterCount;
      }
    }

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
                  Icons.schedule_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Peak Reading Hours',
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
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stats.dominantReadingTimeOfDay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your 24-hour reading activity distribution.',
              style: TextStyle(
                fontSize: AppTypography.xs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Isolated chart in RepaintBoundary for optimal performance
            RepaintBoundary(
              child: SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(24, (hour) {
                    final count = hour < hourly.length ? hourly[hour].chapterCount : 0;
                    final ratio = (count / maxCount).clamp(0.08, 1.0);
                    final isPeak = count == maxCount && count > 0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Tooltip(
                          message: '$hour:00 - $count chapters',
                          child: Container(
                            height: 60 * ratio,
                            decoration: BoxDecoration(
                              color: isPeak
                                  ? colorScheme.primary
                                  : (count > 0
                                      ? colorScheme.primary.withValues(alpha: 0.45)
                                      : colorScheme.outlineVariant.withValues(alpha: 0.25)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Axis labels: 12 AM, 6 AM, 12 PM, 6 PM, 11 PM
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('12 AM', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                Text('6 AM', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                Text('12 PM', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                Text('6 PM', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                Text('11 PM', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
