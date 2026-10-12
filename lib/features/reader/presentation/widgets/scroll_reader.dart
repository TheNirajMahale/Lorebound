import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart' hide Image;
import '../../domain/models/reader_config.dart';
import '../../data/services/epub_parser_service_provider.dart';
import '../providers/reader_state_providers.dart';
import '../providers/reader_controller.dart';
import 'chapter_scroll_view.dart';
import 'reader_bars.dart';

class ScrollReader extends ConsumerStatefulWidget {
  final EpubBook book;
  final ReaderConfig config;
  final VoidCallback onBackPressed;

  const ScrollReader({
    super.key,
    required this.book,
    required this.config,
    required this.onBackPressed,
  });

  @override
  ConsumerState<ScrollReader> createState() => _ScrollReaderState();
}

class _ScrollReaderState extends ConsumerState<ScrollReader> {
  List<EpubChapter> _chapters = [];
  List<String> _cachedChapterTitles = [];
  bool _hasCover = false;
  late PageController _pageController;
  int _currentPageIndex = 0;

  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _matchCount = 0;
  int _currentMatchIndex = 0;
  double? _savedReadingScrollOffset;
  double? _resumeScrollOffset;

  final ValueNotifier<double> _verticalScrollOffset = ValueNotifier<double>(
    0.0,
  );
  bool _isAutoScrollPaused = false;

  @override
  void initState() {
    super.initState();
    final initialProgress = ref.read(readerProgressProvider);
    _currentPageIndex = initialProgress.chapterIndex;
    _pageController = PageController(initialPage: _currentPageIndex);
    final parser = ref.read(epubParserServiceProvider);
    _chapters = parser.flattenChapters(widget.book.Chapters);
    _hasCover = _getCoverKey().isNotEmpty;
    _cachedChapterTitles = [
      if (_hasCover) 'Cover',
      ..._chapters.asMap().entries.map((entry) {
        final title = entry.value.Title?.trim();
        return (title != null && title.isNotEmpty)
            ? title
            : 'Chapter ${entry.key + 1}';
      }),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _verticalScrollOffset.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScrollReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.config.autoScrollEnabled && oldWidget.config.autoScrollEnabled) {
      _isAutoScrollPaused = false;
    }
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
      _savedReadingScrollOffset = _verticalScrollOffset.value;
    });
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentMatchIndex = 0;
      _savedReadingScrollOffset ??= _verticalScrollOffset.value;
    });
  }

  void _onNextMatch() {
    if (_matchCount <= 1) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchCount;
    });
  }

  void _onPrevMatch() {
    if (_matchCount <= 1) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchCount) % _matchCount;
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearchOpen = false;
      _searchController.clear();
      _searchQuery = '';
      _matchCount = 0;
      _currentMatchIndex = 0;
      _savedReadingScrollOffset = null;
      _resumeScrollOffset = null;
    });
  }

  void _resumeReading() {
    if (_savedReadingScrollOffset != null) {
      setState(() {
        _resumeScrollOffset = _savedReadingScrollOffset;
        _savedReadingScrollOffset = null;
      });
    }
  }

  void _onResumeCompleted() {
    if (mounted) {
      setState(() {
        _resumeScrollOffset = null;
      });
    }
  }

  String _getCoverKey() {
    return ref.read(epubParserServiceProvider).getCoverKey(widget.book);
  }

  void _jumpToChapter(int index) {
    int maxIndex = _chapters.length - 1 + (_hasCover ? 1 : 0);
    if (index < 0 || index > maxIndex) return;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
    setState(() {
      _currentPageIndex = index;
      _verticalScrollOffset.value = 0.0;
    });
    ref.read(readerProgressProvider.notifier).updateChapter(index);
  }

  @override
  Widget build(BuildContext context) {
    if (_chapters.isEmpty) {
      return Container(color: widget.config.backgroundColor);
    }

    final chapterTitle = (_currentPageIndex < _cachedChapterTitles.length)
        ? _cachedChapterTitles[_currentPageIndex]
        : 'Chapter $_currentPageIndex';

    int maxIndex = _chapters.length - 1 + (_hasCover ? 1 : 0);
    int pageCount = maxIndex + 1;

    return Scaffold(
      backgroundColor: widget.config.backgroundColor,
      appBar: ReaderTopBar(
        chapterTitle: chapterTitle,
        config: widget.config,
        onBackPressed: widget.onBackPressed,
        onSearchTap: _openSearch,
        isSearchOpen: _isSearchOpen,
        searchController: _searchController,
        onCloseSearch: _closeSearch,
        onSearchQueryChanged: _onSearchQueryChanged,
        matchCount: _matchCount,
        currentMatchIndex: _currentMatchIndex,
        onNextMatch: _onNextMatch,
        onPrevMatch: _onPrevMatch,
      ),
      bottomNavigationBar: ReaderBottomBar(
        config: widget.config,
        progressText: '',
        chapters: _cachedChapterTitles,
        currentChapterIndex: _currentPageIndex,
        onChapterSelected: _jumpToChapter,
        bookTitle: widget.book.Title ?? 'Unknown Title',
        author: widget.book.Author,
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                _verticalScrollOffset.value = notification.metrics.pixels;
                final double max = notification.metrics.maxScrollExtent;
                final double progress = max > 0
                    ? (notification.metrics.pixels / max).clamp(0.0, 1.0)
                    : 0.0;
                ref.read(readerProgressProvider.notifier).updateProgress(_currentPageIndex, progress);
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: pageCount,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
                ref.read(readerProgressProvider.notifier).updateChapter(index);
                _verticalScrollOffset.value = 0.0;
              },
              itemBuilder: (context, index) {
                if (_hasCover && index == 0) {
                  final coverKey = _getCoverKey();
                  return RepaintBoundary(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Image.memory(
                          Uint8List.fromList(
                            widget.book.Content!.Images![coverKey]!.Content!,
                          ),
                          key: ValueKey(coverKey),
                          gaplessPlayback: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }

                final idx = _hasCover ? index - 1 : index;
                final clampedIdx = _chapters.isEmpty ? 0 : idx.clamp(0, _chapters.length - 1);
                final chapter = _chapters.isEmpty ? EpubChapter() : _chapters[clampedIdx];
                final initialProgressState = ref.read(readerProgressProvider);
                
                return RepaintBoundary(
                  child: ChapterScrollView(
                    key: ValueKey(chapter.Title ?? idx.toString()),
                    chapter: chapter,
                    book: widget.book,
                    topPadding: 0.0,
                    bottomPadding: 0.0,
                    initialProgress: (index == initialProgressState.chapterIndex)
                        ? initialProgressState.progress
                        : 0.0,
                    searchQuery: (index == _currentPageIndex) ? _searchQuery : null,
                    currentMatchIndex: (index == _currentPageIndex) ? _currentMatchIndex : 0,
                    onMatchCountChanged: (count) {
                      if (index == _currentPageIndex && _matchCount != count && mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _matchCount != count) {
                            setState(() => _matchCount = count);
                          }
                        });
                      }
                    },
                    resumeOffset: (index == _currentPageIndex) ? _resumeScrollOffset : null,
                    onResumeCompleted: _onResumeCompleted,
                    autoScrollEnabled: (index == _currentPageIndex)
                        ? (widget.config.autoScrollEnabled && !_isAutoScrollPaused)
                        : false,
                    autoScrollSpeed: widget.config.autoScrollSpeed,
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _verticalScrollOffset,
            builder: (context, currentOffset, _) {
              final bool canResume = _savedReadingScrollOffset != null &&
                  (currentOffset - _savedReadingScrollOffset!).abs() > 40.0;

              return Positioned(
                bottom: 16.0,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    offset: canResume ? Offset.zero : const Offset(0, 1.5),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: canResume ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !canResume,
                        child: Material(
                          elevation: 6.0,
                          borderRadius: BorderRadius.circular(24.0),
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shadowColor: Colors.black45,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24.0),
                            onTap: _resumeReading,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resume reading',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Floating Auto-Scroll Controls (Pause / Resume / Dismiss)
          if (widget.config.autoScrollEnabled)
            Positioned(
              bottom: 20.0,
              right: 16.0,
              child: Material(
                elevation: 6.0,
                borderRadius: BorderRadius.circular(28.0),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shadowColor: Colors.black45,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pause / Resume Toggle
                      InkWell(
                        borderRadius: BorderRadius.circular(20.0),
                        onTap: () {
                          setState(() {
                            _isAutoScrollPaused = !_isAutoScrollPaused;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAutoScrollPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                size: 20,
                                color: _isAutoScrollPaused
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAutoScrollPaused ? 'Resume' : 'Pause',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isAutoScrollPaused
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      // Speed indicator badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '${widget.config.autoScrollSpeed.toInt()} px/s',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Turn Off / Dismiss Button
                      InkWell(
                        borderRadius: BorderRadius.circular(16.0),
                        onTap: () {
                          ref.read(readerControllerProvider.notifier).updateConfig(
                            widget.config.copyWith(autoScrollEnabled: false),
                          );
                          setState(() {
                            _isAutoScrollPaused = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
