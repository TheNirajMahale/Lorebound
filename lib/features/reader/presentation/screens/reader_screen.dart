import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../library/data/repositories/local_book_repository.dart';
import '../providers/reader_controller.dart';
import '../providers/reader_state_providers.dart';
import '../widgets/native_scroll_reader.dart';
import '../widgets/native_paginated_reader.dart';
import '../../domain/models/reader_config.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final String filePath;
  final int? initialChapter;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.filePath,
    this.initialChapter,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  Timer? _saveDebouncer;
  late final LocalBookRepository _repo;
  ReaderProgress? _lastProgress;
  bool _isInitializing = true;

  void _saveProgress(int chapterIndex, double progress) {
    if (widget.bookId < 0) return;
    
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _repo.updateBookProgress(widget.bookId, chapterIndex, progress.toString());
      }
    });
  }

  @override
  void initState() {
    super.initState();
    
    // We must wait for the first frame to render before mutating watched providers.
    // Otherwise, Riverpod throws a StateError which is swallowed by the catch block,
    // leaving the screen stuck on the initial data(null) spinner forever!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Hide status bar but keep bottom navigation bar permanent
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      );

      _repo = ref.read(localBookRepositoryProvider);

      _loadBookInitialState().catchError((e) {
        debugPrint('Error during initialization: $e');
      });
    });
  }

  Future<void> _loadBookInitialState() async {
    try {
      int startChapter = 0;
      double startProgress = 0.0;

      if (widget.initialChapter != null) {
        startChapter = widget.initialChapter!;
      } else if (widget.bookId >= 0) {
        final book = await _repo.getBookById(widget.bookId);
        if (book != null) {
          startChapter = book.currentChapter;
          startProgress = double.tryParse(book.readingPosition ?? '0.0') ?? 0.0;
        }
      }

      if (mounted) {
        ref.read(readerProgressProvider.notifier).updateProgress(startChapter, startProgress);
        ref.read(readerBookProvider.notifier).loadBook(widget.filePath, isAsset: false);
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e, st) {
      debugPrint('Exception in _loadBookInitialState: $e\n$st');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    // Do one final immediate save on exit if we have a valid ID
    if (widget.bookId >= 0 && _lastProgress != null) {
      _repo.updateBookProgress(widget.bookId, _lastProgress!.chapterIndex, _lastProgress!.progress.toString());
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    ref.listen(readerProgressProvider, (previous, next) {
      _lastProgress = next;
      if (previous?.chapterIndex != next.chapterIndex || previous?.progress != next.progress) {
        _saveProgress(next.chapterIndex, next.progress);
      }
    });

    final readerState = ref.watch(readerControllerProvider);
    final bookState = ref.watch(readerBookProvider);

    final isDark = readerState.config.themePreset == ReaderThemePreset.dark ||
        readerState.config.themePreset == ReaderThemePreset.black ||
        readerState.config.themePreset == ReaderThemePreset.grey;

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
        backgroundColor: readerState.config.backgroundColor,
        body: Stack(
          children: [
            // The Reader Surface
            if (_isInitializing)
              Center(
                child: CircularProgressIndicator(
                  color: readerState.config.textColor.withValues(alpha: 0.5),
                ),
              )
            else
              bookState.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: readerState.config.textColor.withValues(alpha: 0.5),
                  ),
                ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading book:\n$err',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (book) {
                if (book != null) {
                  return readerState.config.mode == ReaderMode.scroll
                      ? NativeScrollReader(
                          key: ValueKey(book.hashCode),
                          book: book,
                          config: readerState.config,
                          onBackPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                        )
                      : NativePaginatedReader(
                          key: ValueKey(book.hashCode),
                          book: book,
                          config: readerState.config,
                          onBackPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                        );
                }
                return Center(
                  child: CircularProgressIndicator(
                    color: readerState.config.textColor.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
