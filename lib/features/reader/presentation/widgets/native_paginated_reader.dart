import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart' hide Image;
import 'package:html/dom.dart' as dom;
import '../../domain/models/reader_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reader_page.dart';
import '../../data/services/page_chunker_service.dart';
import '../../data/services/epub_parser_service_provider.dart';
import '../../data/services/book_storage_service.dart';
import '../providers/reader_state_providers.dart';
import 'html_node_widget.dart';
import 'reader_bars.dart';

class NativePaginatedReader extends ConsumerStatefulWidget {
  final EpubBook book;
  final ReaderConfig config;
  final VoidCallback onBackPressed;

  const NativePaginatedReader({
    super.key,
    required this.book,
    required this.config,
    required this.onBackPressed,
  });

  @override
  ConsumerState<NativePaginatedReader> createState() =>
      _NativePaginatedReaderState();
}

class _NativePaginatedReaderState extends ConsumerState<NativePaginatedReader> {
  late List<EpubChapter> _chapters;
  List<String> _cachedChapterTitles = [];
  int _currentChapterIndex = 0;
  bool _hasCover = false;

  late PageController _pageController;
  int _currentPageIndex = 0;

  bool _isChunking = false;
  List<ReaderPage> _currentChapterPages = [];
  bool _initialProgressApplied = false;

  double _lastMaxWidth = 0;
  double _lastMaxHeight = 0;

  double _initialProgress = 0.0;
  int _initialChapterIndex = 0;
  String _bookKey = '';

  @override
  void initState() {
    super.initState();
    _bookKey = widget.book.hashCode.toString();
    final progressState = ref.read(readerProgressProvider);
    _initialChapterIndex = progressState.chapterIndex;
    _initialProgress = progressState.progress;
    _currentChapterIndex = _initialChapterIndex;
    _chapters = [];
    _initChaptersAndController();
  }

  void _initChaptersAndController() {
    if (_chapters.isEmpty) {
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

      int dummyStartCount = _currentChapterIndex == 0 ? 0 : 1;
      _pageController = PageController(initialPage: dummyStartCount);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NativePaginatedReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.fontSize != widget.config.fontSize ||
        oldWidget.config.lineSpacing != widget.config.lineSpacing ||
        oldWidget.config.fontFamily != widget.config.fontFamily) {
      if (_lastMaxWidth > 0 && _lastMaxHeight > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _chunkChapter(
              _currentChapterIndex,
              _lastMaxWidth,
              _lastMaxHeight,
              forceLoading: true,
            );
          }
        });
      }
    }
  }

  String _getCoverKey() {
    return ref.read(epubParserServiceProvider).getCoverKey(widget.book);
  }

  Future<List<dom.Node>> _getNodesForChapter(int index) async {
    if (_hasCover && index == 0) return [];
    final idx = _hasCover ? index - 1 : index;

    if (_chapters.isEmpty) return [];
    final clampedIdx = idx.clamp(0, _chapters.length - 1);
    final chapter = _chapters[clampedIdx];

    final storage = ref.read(bookStorageServiceProvider);

    // Check disk cache first for instant reading
    final cached = await storage.getChapterFromDisk(_bookKey, clampedIdx);
    String htmlContent = '';
    if (cached != null && cached['htmlContent']!.isNotEmpty) {
      htmlContent = cached['htmlContent']!;
    } else if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
      htmlContent = chapter.HtmlContent!;
      final title = (chapter.Title?.trim().isNotEmpty ?? false)
          ? chapter.Title!.trim()
          : 'Chapter ${clampedIdx + 1}';
      storage.saveChapterToDisk(_bookKey, clampedIdx, title, htmlContent);
    }

    // Prefetch next chapter in background
    if (clampedIdx + 1 < _chapters.length) {
      _prefetchChapter(clampedIdx + 1);
    }

    List<dom.Node> allNodes = [];
    if (htmlContent.isNotEmpty) {
      final document = dom.Document.html(htmlContent);
      if (document.body != null) {
        for (var node in document.body!.nodes) {
          if (node is dom.Text && node.text.trim().isEmpty) continue;
          if (allNodes.isEmpty && node is dom.Element && node.text.trim().isEmpty) {
            continue;
          }
          allNodes.add(node);
        }
      }
    }
    return allNodes;
  }

  void _prefetchChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) return;
    final storage = ref.read(bookStorageServiceProvider);
    storage.hasChapterOnDisk(_bookKey, chapterIndex).then((exists) {
      if (!exists && mounted) {
        final ch = _chapters[chapterIndex];
        if (ch.HtmlContent != null && ch.HtmlContent!.isNotEmpty) {
          final title = (ch.Title?.trim().isNotEmpty ?? false)
              ? ch.Title!.trim()
              : 'Chapter ${chapterIndex + 1}';
          storage.saveChapterToDisk(
            _bookKey,
            chapterIndex,
            title,
            ch.HtmlContent!,
          );
        }
      }
    });
  }

  Future<void> _chunkChapter(
    int index,
    double maxWidth,
    double maxHeight, {
    bool forceLoading = false,
  }) async {
    if (!mounted) return;

    if (_currentChapterPages.isEmpty || forceLoading) {
      setState(() {
        _isChunking = true;
      });
    }

    _lastMaxWidth = maxWidth;
    _lastMaxHeight = maxHeight;

    List<ReaderPage> pages = [];

    try {
      if (_hasCover && index == 0) {
        pages = [];
      } else {
        final chunker = ref.read(pageChunkerServiceProvider);
        final nodes = await _getNodesForChapter(index);

        pages = await chunker.chunkChapter(
          bookId: _bookKey,
          chapterIndex: index,
          allNodes: nodes,
          maxWidth: maxWidth - 48.0,
          maxHeight: maxHeight,
          config: widget.config,
        );
      }

      // Guarantee at least 1 content page so rendering never stalls
      if (pages.isEmpty && !(_hasCover && index == 0)) {
        final chTitle = (index < _cachedChapterTitles.length)
            ? _cachedChapterTitles[index]
            : 'Chapter $index';
        final fallbackElement = dom.Element.tag('p')..text = chTitle;
        pages = [
          ReaderPage(
            chapterIndex: index,
            pageIndex: 0,
            nodes: [fallbackElement],
          ),
        ];
      }
    } catch (e, st) {
      debugPrint('Error chunking chapter $index: $e\n$st');
      final fallbackElement = dom.Element.tag('p')..text = 'Chapter $index';
      pages = [
        ReaderPage(chapterIndex: index, pageIndex: 0, nodes: [fallbackElement]),
      ];
    } finally {
      if (mounted) {
        int targetPage = 0;
        if (!_initialProgressApplied && index == _initialChapterIndex) {
          _initialProgressApplied = true;
          if (_initialProgress > 0 && pages.isNotEmpty) {
            int rawTargetPage = ((pages.length - 1) * _initialProgress).round();
            targetPage = (rawTargetPage > 0 ? rawTargetPage - 1 : 0).clamp(
              0,
              pages.length - 1,
            );
          }
        } else if (_currentChapterPages.isNotEmpty && pages.isNotEmpty) {
          final double progress =
              (_currentPageIndex /
                      (_currentChapterPages.length > 1
                          ? _currentChapterPages.length - 1
                          : 1))
                  .clamp(0.0, 1.0);
          targetPage = (progress * (pages.length - 1)).round().clamp(
            0,
            pages.length - 1,
          );
        }

        setState(() {
          _currentChapterPages = pages;
          _isChunking = false;
          _currentPageIndex = targetPage;
        });

        _safeJumpToPage(targetPage);
      }
    }
  }

  void _safeJumpToPage(int targetContentPageIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final int dummyStartCount = _currentChapterIndex == 0 ? 0 : 1;
        final int target = dummyStartCount + targetContentPageIndex;
        _pageController.jumpToPage(target);
      }
    });
  }

  Future<void> _goToNextChapter() async {
    int maxIndex = _chapters.length - 1 + (_hasCover ? 1 : 0);
    if (_currentChapterIndex < maxIndex) {
      setState(() {
        _currentChapterIndex++;
        _currentPageIndex = 0;
      });
      ref
          .read(readerProgressProvider.notifier)
          .updateChapter(_currentChapterIndex);
      await _chunkChapter(
        _currentChapterIndex,
        _lastMaxWidth,
        _lastMaxHeight,
        forceLoading: true,
      );
      _safeJumpToPage(0);
    }
  }

  Future<void> _goToPreviousChapter() async {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      ref
          .read(readerProgressProvider.notifier)
          .updateChapter(_currentChapterIndex);
      await _chunkChapter(
        _currentChapterIndex,
        _lastMaxWidth,
        _lastMaxHeight,
        forceLoading: true,
      );

      final int lastPageIndex = (_hasCover && _currentChapterIndex == 0)
          ? 0
          : (_currentChapterPages.isNotEmpty
                ? _currentChapterPages.length - 1
                : 0);

      setState(() {
        _currentPageIndex = lastPageIndex;
      });
      _safeJumpToPage(lastPageIndex);
    }
  }

  Future<void> _jumpToChapter(int index) async {
    int maxIndex = _chapters.length - 1 + (_hasCover ? 1 : 0);
    if (index < 0 || index > maxIndex) return;
    setState(() {
      _currentChapterIndex = index;
      _currentPageIndex = 0;
    });
    ref
        .read(readerProgressProvider.notifier)
        .updateChapter(_currentChapterIndex);
    await _chunkChapter(
      _currentChapterIndex,
      _lastMaxWidth,
      _lastMaxHeight,
      forceLoading: true,
    );
    _safeJumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    _initChaptersAndController();

    if (_chapters.isEmpty) {
      return Container(color: widget.config.backgroundColor);
    }

    final isCover = _hasCover && _currentChapterIndex == 0;
    final chapterTitle = (_currentChapterIndex < _cachedChapterTitles.length)
        ? _cachedChapterTitles[_currentChapterIndex]
        : 'Chapter $_currentChapterIndex';

    return Scaffold(
      backgroundColor: widget.config.backgroundColor,
      appBar: ReaderTopBar(
        chapterTitle: chapterTitle,
        config: widget.config,
        onBackPressed: widget.onBackPressed,
      ),
      bottomNavigationBar: ReaderBottomBar(
        config: widget.config,
        progressText: _isChunking || isCover
            ? ''
            : 'Page ${_currentPageIndex + 1} of ${_currentChapterPages.length}',
        chapters: _cachedChapterTitles,
        currentChapterIndex: _currentChapterIndex,
        onChapterSelected: _jumpToChapter,
        bookTitle: widget.book.Title ?? 'Unknown Title',
        author: widget.book.Author,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Only re-chunk if the width changes drastically (e.g., device rotation).
          // This absolutely prevents any microscopic vertical layout instability loops
          // caused by bottom bars appearing/disappearing.
          final widthDiff = (constraints.maxWidth - _lastMaxWidth).abs();
          
          if (widthDiff > 50.0 && _lastMaxWidth > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _chunkChapter(_currentChapterIndex, constraints.maxWidth, constraints.maxHeight, forceLoading: true);
              }
            });
          } else if (_lastMaxWidth == 0) {
             // Initial load
             WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _chunkChapter(_currentChapterIndex, constraints.maxWidth, constraints.maxHeight);
              }
            });
          }

          final bool isFirstChapter = _currentChapterIndex == 0;
          final bool isLastChapter =
              _currentChapterIndex ==
              _chapters.length - 1 + (_hasCover ? 1 : 0);

          final int dummyStartCount = isFirstChapter ? 0 : 1;
          final int dummyEndCount = isLastChapter ? 0 : 1;
          final int contentPageCount = isCover
              ? 1
              : (_currentChapterPages.isNotEmpty
                    ? _currentChapterPages.length
                    : 1);
          final int totalItems =
              dummyStartCount + contentPageCount + dummyEndCount;

          return Stack(
            children: [
              PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: totalItems,
                  onPageChanged: (index) {
                    if (index < dummyStartCount) {
                      _goToPreviousChapter();
                    } else if (index >= dummyStartCount + contentPageCount) {
                      _goToNextChapter();
                    } else {
                      final int newContentIdx = index - dummyStartCount;
                      setState(() {
                        _currentPageIndex = newContentIdx;
                      });
                      final int count = isCover
                          ? 1
                          : _currentChapterPages.length;
                      final double progress = count > 1
                          ? (_currentPageIndex / (count - 1)).clamp(0.0, 1.0)
                          : 0.0;
                      ref
                          .read(readerProgressProvider.notifier)
                          .updateProgress(_currentChapterIndex, progress);
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index < dummyStartCount ||
                        index >= dummyStartCount + contentPageCount) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: widget.config.textColor.withValues(alpha: 0.5),
                        ),
                      );
                    }

                    final int contentIndex = index - dummyStartCount;

                    if (isCover) {
                      final coverKey = _getCoverKey();
                      return RepaintBoundary(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Image.memory(
                              Uint8List.fromList(
                                widget
                                    .book
                                    .Content!
                                    .Images![coverKey]!
                                    .Content!,
                              ),
                              key: ValueKey(coverKey),
                              gaplessPlayback: true,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    }

                    if (_currentChapterPages.isEmpty ||
                        contentIndex >= _currentChapterPages.length) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: widget.config.textColor.withValues(alpha: 0.5),
                        ),
                      );
                    }

                    final page = _currentChapterPages[contentIndex];

                    return RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ClipRect(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: page.nodes.asMap().entries.map((entry) {
                                return HtmlNodeWidget(
                                  node: entry.value,
                                  book: widget.book,
                                  isFirstNode: entry.key == 0,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_isChunking && _currentChapterPages.isEmpty)
                  Container(
                    color: widget.config.backgroundColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: widget.config.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
  }
}
