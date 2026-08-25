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
import '../widgets/reader_bars.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/models/reader_config.dart';
import '../../../history/data/repositories/reading_history_repository.dart';
import '../../../history/presentation/providers/history_controller.dart';
import '../../../more/presentation/providers/more_provider.dart';
import '../../data/services/epub_parser_service_provider.dart';

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
  String? _loadingTitle;
  String? _loadingAuthor;

  void _saveProgress(int chapterIndex, double progress) {
    if (widget.bookId < 0) return;
    
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _repo.updateBookProgress(widget.bookId, chapterIndex, progress.toString());
      }
    });
  }
  
  void _recordHistory(int chapterIndex) {
    if (widget.bookId < 0) return;
    
    // Check incognito mode
    final isIncognito = ref.read(incognitoModeProvider);
    if (isIncognito) return;
    
    final bookState = ref.read(readerBookProvider);
    bookState.whenData((book) {
      if (book != null && chapterIndex >= 0) {
        final parser = ref.read(epubParserServiceProvider);
        final chapters = parser.flattenChapters(book.Chapters);
        final hasCover = parser.getCoverKey(book).isNotEmpty;
        
        String resolvedTitle;
        if (hasCover) {
          if (chapterIndex == 0) {
            resolvedTitle = 'Cover';
          } else {
            final idx = chapterIndex - 1;
            if (idx >= 0 && idx < chapters.length) {
               final t = chapters[idx].Title?.trim();
               resolvedTitle = (t != null && t.isNotEmpty) ? t : 'Chapter $chapterIndex';
            } else {
               resolvedTitle = 'Chapter $chapterIndex';
            }
          }
        } else {
          if (chapterIndex >= 0 && chapterIndex < chapters.length) {
             final t = chapters[chapterIndex].Title?.trim();
             resolvedTitle = (t != null && t.isNotEmpty) ? t : 'Chapter ${chapterIndex + 1}';
          } else {
             resolvedTitle = 'Chapter ${chapterIndex + 1}';
          }
        }

        ref.read(readingHistoryRepositoryProvider).addHistoryEntry(
          bookId: widget.bookId,
          chapterIndex: chapterIndex,
          chapterTitle: resolvedTitle,
        );
        // Refresh history screen
        ref.invalidate(historyControllerProvider);
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
          if (mounted) {
            setState(() {
              _loadingTitle = book.title;
              _loadingAuthor = book.author;
            });
          }
        }
      }

      if (mounted) {
        ref.read(readerProgressProvider.notifier).updateProgress(startChapter, startProgress);
        ref.read(readerBookProvider.notifier).loadBook(widget.filePath, isAsset: false, bookId: widget.bookId);
        
        // Record initial opening in history
        _recordHistory(startChapter);
        
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
      if (previous?.chapterIndex != next.chapterIndex && next.chapterIndex >= 0) {
        _recordHistory(next.chapterIndex);
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

    final isLoaded = !_isInitializing && !bookState.isLoading && !bookState.hasError && bookState.hasValue;

    final loadingTopBar = ReaderTopBar(
      chapterTitle: _loadingTitle ?? 'Loading...',
      config: readerState.config,
      onBackPressed: () {
        if (context.canPop()) {
          context.pop();
        }
      },
    );

    final loadingBottomBar = ReaderBottomBar(
      config: readerState.config,
      progressText: 'Parsing book...',
      chapters: const [],
      currentChapterIndex: 0,
      onChapterSelected: null,
      bookTitle: _loadingTitle ?? 'Loading...',
      author: _loadingAuthor,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
        backgroundColor: readerState.config.backgroundColor,
        appBar: !isLoaded ? loadingTopBar : null,
        bottomNavigationBar: !isLoaded ? loadingBottomBar : null,
        body: Stack(
          children: [
            // The Reader Surface
            if (_isInitializing)
              const Center(child: AppLoadingIndicator())
            else
              bookState.when(
                loading: () => const Center(child: AppLoadingIndicator()),
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
