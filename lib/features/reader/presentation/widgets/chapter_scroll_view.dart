import 'dart:async';
import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../../../core/widgets/app_loading_indicator.dart';
import 'html_node_widget.dart';

class ChapterScrollView extends StatefulWidget {
  final EpubChapter chapter;
  final EpubBook book;
  final double topPadding;
  final double bottomPadding;
  final double initialProgress;
  final String? searchQuery;
  final int currentMatchIndex;
  final ValueChanged<int>? onMatchCountChanged;
  final double? resumeOffset;
  final VoidCallback? onResumeCompleted;
  final bool autoScrollEnabled;
  final double autoScrollSpeed;

  const ChapterScrollView({
    super.key,
    required this.chapter,
    required this.book,
    required this.topPadding,
    this.bottomPadding = 40.0,
    this.initialProgress = 0.0,
    this.searchQuery,
    this.currentMatchIndex = 0,
    this.onMatchCountChanged,
    this.resumeOffset,
    this.onResumeCompleted,
    this.autoScrollEnabled = false,
    this.autoScrollSpeed = 40.0,
  });

  @override
  State<ChapterScrollView> createState() => _ChapterScrollViewState();
}

class _ChapterMatch {
  final int nodeIndex;
  final int matchIndexInNode;
  final int charOffsetInChapter;

  const _ChapterMatch({
    required this.nodeIndex,
    required this.matchIndexInNode,
    required this.charOffsetInChapter,
  });
}

class _ChapterScrollViewState extends State<ChapterScrollView> {
  List<dom.Node> _parsedNodes = [];
  List<int> _cumulativeChars = [];
  int _totalChars = 1;
  List<_ChapterMatch> _matches = [];
  int _currentMatchNodeIndex = -1;
  bool _isLoading = true;
  late ScrollController _scrollController;
  bool _initialProgressRestored = false;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _parseChapter().catchError((e) {
      debugPrint('Error parsing chapter for scroll view: $e');
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChapterScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter != widget.chapter) {
      _initialProgressRestored = false;
      _parseChapter().catchError((e) {
        debugPrint('Error parsing chapter for scroll view on update: $e');
      });
    }

    if (widget.resumeOffset != null && widget.resumeOffset != oldWidget.resumeOffset) {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final target = widget.resumeOffset!.clamp(0.0, max);
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        ).then((_) {
          widget.onResumeCompleted?.call();
        });
      }
    } else if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.currentMatchIndex != widget.currentMatchIndex) {
      _handleSearchUpdate();
    }

    if (widget.autoScrollEnabled != oldWidget.autoScrollEnabled ||
        widget.autoScrollSpeed != oldWidget.autoScrollSpeed) {
      _manageAutoScroll();
    }
  }

  void _manageAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.autoScrollEnabled && !_userInteracting) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted || !_scrollController.hasClients || _userInteracting) return;
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        if (current >= max) {
          _autoScrollTimer?.cancel();
          return;
        }
        final step = (widget.autoScrollSpeed * 0.016);
        _scrollController.jumpTo((current + step).clamp(0.0, max));
      });
    }
  }

  String _getNodeText(dom.Node node) {
    if (node is dom.Text) {
      return node.text;
    } else if (node is dom.Element) {
      return node.text;
    }
    return '';
  }

  void _handleSearchUpdate() {
    final query = widget.searchQuery?.trim() ?? '';
    if (query.isEmpty) {
      if (_matches.isNotEmpty || _currentMatchNodeIndex != -1) {
        setState(() {
          _matches = [];
          _currentMatchNodeIndex = -1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onMatchCountChanged?.call(0);
          }
        });
      }
      return;
    }

    final lowerQuery = query.toLowerCase();
    final List<_ChapterMatch> matches = [];

    for (int i = 0; i < _parsedNodes.length; i++) {
      final text = _getNodeText(_parsedNodes[i]).toLowerCase();
      int occurrence = 0;
      int startIndex = 0;
      final nodeStartChar = i < _cumulativeChars.length ? _cumulativeChars[i] : 0;
      while (true) {
        final idx = text.indexOf(lowerQuery, startIndex);
        if (idx == -1) break;
        matches.add(_ChapterMatch(
          nodeIndex: i,
          matchIndexInNode: occurrence,
          charOffsetInChapter: nodeStartChar + idx,
        ));
        occurrence++;
        startIndex = idx + lowerQuery.length;
      }
    }

    int targetNodeIndex = -1;
    _ChapterMatch? targetMatch;
    if (matches.isNotEmpty) {
      final clampedIdx = widget.currentMatchIndex.clamp(0, matches.length - 1);
      targetMatch = matches[clampedIdx];
      targetNodeIndex = targetMatch.nodeIndex;
    }

    setState(() {
      _matches = matches;
      _currentMatchNodeIndex = targetNodeIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onMatchCountChanged?.call(matches.length);
        if (targetMatch != null) {
          _scrollToMatch(targetMatch);
        }
      }
    });
  }

  void _scrollToMatch(_ChapterMatch match) {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final maxExtent = pos.maxScrollExtent;
    final viewport = pos.viewportDimension;
    if (maxExtent <= 0 || _totalChars <= 0) return;

    // Total physical scrollable height
    final totalContentHeight = maxExtent + viewport;
    // Exact character progress through chapter
    final ratio = (match.charOffsetInChapter / _totalChars).clamp(0.0, 1.0);
    final matchYInContent = ratio * totalContentHeight;

    // Position match comfortably near top of visible viewport (~28px below top search bar)
    // so it is always clearly visible at the top, completely clear of the keyboard
    const topClearance = 28.0;
    final targetOffset = (matchYInContent - topClearance).clamp(0.0, maxExtent);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _parseChapter() async {
    setState(() => _isLoading = true);

    // Yield to the event loop for smooth PageView animations
    await Future.delayed(const Duration(milliseconds: 16));

    List<dom.Node> allNodes = [];

    if (widget.chapter.HtmlContent != null &&
        widget.chapter.HtmlContent!.isNotEmpty) {
      final document = html_parser.parse(widget.chapter.HtmlContent!);
      if (document.body != null) {
        for (var node in document.body!.nodes) {
          // Skip raw whitespace text nodes
          if (node is dom.Text && node.text.trim().isEmpty) {
            continue;
          }
          // Skip completely empty spacer elements at the very beginning of the chapter
          if (allNodes.isEmpty &&
              node is dom.Element &&
              node.text.trim().isEmpty) {
            continue;
          }
          allNodes.add(node);
        }
      }
    }

    if (mounted) {
      int sum = 0;
      final cumulative = <int>[];
      for (final n in allNodes) {
        cumulative.add(sum);
        sum += _getNodeText(n).length;
      }

      setState(() {
        _parsedNodes = allNodes;
        _cumulativeChars = cumulative;
        _totalChars = sum > 0 ? sum : 1;
        _isLoading = false;
      });

      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        _handleSearchUpdate();
      }

      if (!_initialProgressRestored && widget.initialProgress > 0) {
        _initialProgressRestored = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final max = _scrollController.position.maxScrollExtent;
            if (max > 0) {
              final rawOffset = max * widget.initialProgress;
              // Subtract ~0.7 screen height for context overlap so the user never misses a sentence
              final screenHeight = MediaQuery.of(context).size.height;
              final buffer = screenHeight * 0.7;
              final targetOffset = (rawOffset - buffer).clamp(0.0, max);
              _scrollController.jumpTo(targetOffset);
            }
          }
        });
      }

      _manageAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification && notification.dragDetails != null) {
            _userInteracting = true;
          } else if (notification is ScrollEndNotification) {
            _userInteracting = false;
            _manageAutoScroll();
          }
          return false;
        },
        child: Builder(
          builder: (context) {
            final hasSearch = widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty;
            final dynamicBottomPadding = hasSearch
                ? (MediaQuery.of(context).size.height * 0.65)
                : widget.bottomPadding;

            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: widget.topPadding,
                bottom: dynamicBottomPadding,
                left: 24.0,
                right: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(_parsedNodes.length, (index) {
                  final isCurrentMatchNode = (_currentMatchNodeIndex == index);
                  return HtmlNodeWidget(
                    node: _parsedNodes[index],
                    book: widget.book,
                    isFirstNode: index == 0,
                    searchQuery: widget.searchQuery,
                    isCurrentMatch: isCurrentMatchNode,
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}
