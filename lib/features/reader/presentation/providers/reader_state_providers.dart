import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart';
import '../../data/services/epub_parser_service_provider.dart';

// --- Progress State ---
class ReaderProgress {
  final int chapterIndex;
  final double progress;

  const ReaderProgress({this.chapterIndex = 0, this.progress = 0.0});

  ReaderProgress copyWith({int? chapterIndex, double? progress}) {
    return ReaderProgress(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      progress: progress ?? this.progress,
    );
  }
}

class ReaderProgressNotifier extends Notifier<ReaderProgress> {
  @override
  ReaderProgress build() => const ReaderProgress();

  void updateProgress(int index, double progress) {
    state = state.copyWith(chapterIndex: index, progress: progress);
  }

  void updateChapter(int index) {
    state = state.copyWith(chapterIndex: index, progress: 0.0);
  }
}

final readerProgressProvider = NotifierProvider.autoDispose<ReaderProgressNotifier, ReaderProgress>(() {
  return ReaderProgressNotifier();
});

// --- Book State ---
class ReaderBookNotifier extends AsyncNotifier<EpubBook?> {
  String? _currentPath;
  bool _mounted = true;

  @override
  Future<EpubBook?> build() async {
    ref.onDispose(() {
      _mounted = false;
    });
    return null;
  }

  Future<void> loadBook(String path, {required bool isAsset}) async {
    // build() is async and resolves to null on the next microtask. If we set
    // state before build() finishes, build()'s resolution will overwrite our
    // value with data(null), trapping the UI in a spinner. Waiting for
    // `future` guarantees build() has settled before we touch state.
    if (!state.hasValue) {
      try { await future; } catch (_) {}
    }

    if (_currentPath == path && state.hasValue && state.value != null) {
      return;
    }

    final parserService = ref.read(epubParserServiceProvider);

    final cachedBook = parserService.getCachedBook(path);
    if (cachedBook != null) {
      _currentPath = path;
      state = AsyncValue.data(cachedBook);
      return;
    }

    state = const AsyncValue.loading();
    _currentPath = path;

    try {
      final book = isAsset
          ? await parserService.loadBookFromAsset(path)
          : await parserService.loadBookFromFile(path);

      if (_mounted) {
        state = AsyncValue.data(book);
      }
    } catch (e, st) {
      if (_mounted) {
        _currentPath = null;
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final readerBookProvider = AsyncNotifierProvider.autoDispose<ReaderBookNotifier, EpubBook?>(() {
  return ReaderBookNotifier();
});
