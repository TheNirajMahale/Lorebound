import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportResult {
  final String title;
  final bool skippedAsDuplicate;
  final bool failed;

  const ImportResult(
    this.title, {
    this.skippedAsDuplicate = false,
    this.failed = false,
  });
}

class ImportResultsNotifier extends Notifier<List<ImportResult>> {
  @override
  List<ImportResult> build() => [];

  void addResult(ImportResult result) {
    state = [...state, result];
  }

  void clear() {
    state = [];
  }
}

final importResultsProvider =
    NotifierProvider<ImportResultsNotifier, List<ImportResult>>(() {
  return ImportResultsNotifier();
});
