import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reading_statistics.dart';

class StatsKpiRibbonCard extends StatelessWidget {
  final ReadingStatistics stats;

  const StatsKpiRibbonCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                title: 'Total Time',
                value: stats.formattedTotalTime,
                icon: Icons.timer_outlined,
                colorScheme: colorScheme,
              ),
            ),
            Container(
              height: 36,
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Expanded(
              child: _buildMetricItem(
                context,
                title: 'Chapters',
                value: '${stats.totalChaptersFinished}',
                icon: Icons.auto_stories_outlined,
                colorScheme: colorScheme,
              ),
            ),
            Container(
              height: 36,
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Expanded(
              child: _buildMetricItem(
                context,
                title: 'Active Days',
                value: '${stats.activeDaysThisMonth}',
                icon: Icons.calendar_today_outlined,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: colorScheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.xs,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.lg,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
