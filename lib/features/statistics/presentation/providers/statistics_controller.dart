import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_statistics_repository.dart';
import '../../domain/models/reading_statistics.dart';

final readingStatisticsProvider = FutureProvider.autoDispose<ReadingStatistics>((ref) async {
  final repo = ref.watch(readingStatisticsRepositoryProvider);
  return repo.getAggregatedStatistics();
});

class StatisticsController extends AsyncNotifier<ReadingStatistics> {
  @override
  FutureOr<ReadingStatistics> build() async {
    return ref.read(readingStatisticsRepositoryProvider).getAggregatedStatistics();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(readingStatisticsRepositoryProvider).getAggregatedStatistics();
    });
  }

  Future<void> updateStalledBookStatus(int bookId, String newStatus) async {
    await ref.read(readingStatisticsRepositoryProvider).updateBookStatus(bookId, newStatus);
    await refresh();
  }
}

final statisticsControllerProvider =
    AsyncNotifierProvider.autoDispose<StatisticsController, ReadingStatistics>(() {
  return StatisticsController();
});
