import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_history_repository.dart';
import '../../domain/models/history_entry.dart';

class HistoryController extends AsyncNotifier<List<HistoryEntry>> {
  @override
  FutureOr<List<HistoryEntry>> build() async {
    return ref.read(readingHistoryRepositoryProvider).getHistory();
  }

  /// Refresh the history list from the database.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(readingHistoryRepositoryProvider).getHistory();
    });
  }

  /// Delete history entries before a given cutoff.
  Future<void> deleteHistoryBefore(DateTime cutoff) async {
    await ref.read(readingHistoryRepositoryProvider).deleteHistoryBefore(cutoff);
    // Re-fetch from DB instead of going through a loading state,
    // which would flash an empty/black screen momentarily.
    final updated = await ref.read(readingHistoryRepositoryProvider).getHistory();
    state = AsyncData(updated);
  }

  /// Delete all history.
  Future<void> deleteAllHistory() async {
    await ref.read(readingHistoryRepositoryProvider).deleteAllHistory();
    // Set directly to empty list — no need for a loading → data round-trip
    // that causes the black screen flicker.
    state = const AsyncData([]);
  }

  /// Delete a single history entry.
  Future<void> deleteEntry(int id) async {
    await ref.read(readingHistoryRepositoryProvider).deleteHistoryEntry(id);
    // Optimistic removal from local state to avoid full reload
    state = AsyncValue.data(
      state.value?.where((e) => e.id != id).toList() ?? [],
    );
  }
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryEntry>>(() {
  return HistoryController();
});
