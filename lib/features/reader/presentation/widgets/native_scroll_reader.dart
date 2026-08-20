import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epubx/epubx.dart' hide Image;
import '../../domain/models/reader_config.dart';
import '../../data/services/epub_parser_service_provider.dart';
import '../providers/reader_state_providers.dart';
import 'chapter_scroll_view.dart';
import 'reader_bars.dart';

class NativeScrollReader extends ConsumerStatefulWidget {
  final EpubBook book;
  final ReaderConfig config;
  final VoidCallback onBackPressed;

  const NativeScrollReader({
    super.key,
    required this.book,
    required this.config,
    required this.onBackPressed,
  });

  @override
  ConsumerState<NativeScrollReader> createState() => _NativeScrollReaderState();
}

class _NativeScrollReaderState extends ConsumerState<NativeScrollReader> {
  List<EpubChapter> _chapters = [];
  List<String> _cachedChapterTitles = [];
  bool _hasCover = false;
  late PageController _pageController;
  int _currentPageIndex = 0;

  final ValueNotifier<double> _verticalScrollOffset = ValueNotifier<double>(
    0.0,
  );

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
    super.dispose();
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
      body: NotificationListener<ScrollNotification>(
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
              ),
            );
          },
        ),
      ),
    );
  }
}
