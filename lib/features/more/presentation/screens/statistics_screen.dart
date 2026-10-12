import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../statistics/presentation/providers/statistics_controller.dart';
import '../../../statistics/presentation/widgets/stats_kpi_ribbon_card.dart';
import '../../../statistics/presentation/widgets/stalled_books_shelf_card.dart';
import '../../../statistics/presentation/widgets/reading_velocity_card.dart';
import '../../../statistics/presentation/widgets/peak_reading_hours_card.dart';
import '../../../statistics/presentation/widgets/reading_activity_heatmap_card.dart';
import '../../../statistics/presentation/widgets/library_completion_funnel_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(statisticsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Statistics'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh statistics',
            onPressed: () => ref.read(statisticsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: statsState.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonal(
                  onPressed: () => ref.read(statisticsControllerProvider.notifier).refresh(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () => ref.read(statisticsControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. KPI Summary Ribbon (Total Time, Chapters, Active Days)
                StatsKpiRibbonCard(stats: stats),
                const SizedBox(height: AppSpacing.md),

                // 2. 1-Week Stall Tracking Shelf (Actionable)
                StalledBooksShelfCard(
                  stalledBooks: stats.stalledBooks,
                  onMoveToOnHold: (bookId) {
                    ref.read(statisticsControllerProvider.notifier).updateStalledBookStatus(
                          bookId,
                          'ON_HOLD',
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Book moved to On-Hold shelf'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Reading Velocity & Pace Card (WPM, Min/Chapter)
                ReadingVelocityCard(stats: stats),
                const SizedBox(height: AppSpacing.md),

                // 4. Peak Reading Hours (Circadian Distribution)
                PeakReadingHoursCard(stats: stats),
                const SizedBox(height: AppSpacing.md),

                // 5. 30-Day Activity & Streak Heatmap
                ReadingActivityHeatmapCard(stats: stats),
                const SizedBox(height: AppSpacing.md),

                // 6. Library Completion Funnel
                LibraryCompletionFunnelCard(stats: stats),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}
