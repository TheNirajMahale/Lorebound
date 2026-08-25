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

  const ChapterScrollView({
    super.key,
    required this.chapter,
    required this.book,
    required this.topPadding,
    this.bottomPadding = 40.0,
    this.initialProgress = 0.0,
  });

  @override
  State<ChapterScrollView> createState() => _ChapterScrollViewState();
}

class _ChapterScrollViewState extends State<ChapterScrollView> {
  List<dom.Node> _parsedNodes = [];
  bool _isLoading = true;
  late ScrollController _scrollController;
  bool _initialProgressRestored = false;

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
      setState(() {
        _parsedNodes = allNodes;
        _isLoading = false;
      });

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
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          top: widget.topPadding,
          bottom: widget.bottomPadding,
          left: 24.0,
          right: 24.0,
        ),
        itemCount: _parsedNodes.length,
        itemBuilder: (context, index) {
          return HtmlNodeWidget(
            node: _parsedNodes[index],
            book: widget.book,
            isFirstNode: index == 0,
          );
        },
      ),
    );
  }
}
