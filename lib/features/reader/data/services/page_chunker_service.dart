import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import '../../domain/models/reader_config.dart';
import '../../domain/models/reader_page.dart';

final pageChunkerServiceProvider = Provider<PageChunkerService>((ref) {
  return PageChunkerService();
});

class PageChunkerService {
  static final Map<String, List<ReaderPage>> _chunkCache = {};

  /// Takes a list of parsed HTML nodes for a single chapter and mathematically chunks them
  /// into precise physical screen-sized pages based on the provided constraints.
  Future<List<ReaderPage>> chunkChapter({
    required String bookId,
    required int chapterIndex,
    required List<dom.Node> allNodes,
    required double maxWidth,
    required double maxHeight,
    required ReaderConfig config,
  }) async {
    final safeMaxWidth = maxWidth > 50 ? maxWidth : 300.0;
    final safeMaxHeight = maxHeight > 100 ? maxHeight : 600.0;

    final cacheKey = '${bookId}_${chapterIndex}_${safeMaxWidth.toInt()}x${safeMaxHeight.toInt()}_${config.fontSize}_${config.lineSpacing}_${config.fontFamily}';
    if (_chunkCache.containsKey(cacheKey)) {
      return _chunkCache[cacheKey]!;
    }

    List<ReaderPage> pages = [];
    List<dom.Node> currentPageNodes = [];
    double currentHeight = 0;
    int pageIndex = 0;

    final defaultStyle = TextStyle(
      fontSize: config.fontSize,
      height: config.lineSpacing,
      fontFamily: config.fontFamily,
    );

    for (var node in allNodes) {
      if (node is dom.Element) {
        if (node.localName == 'img') {
          double topPadding = currentPageNodes.isNotEmpty ? AppSpacing.md : 0.0;
          double imgHeight = 280.0 + AppSpacing.md + topPadding;
          if (currentHeight + imgHeight > safeMaxHeight && currentPageNodes.isNotEmpty) {
            pages.add(ReaderPage(chapterIndex: chapterIndex, pageIndex: pageIndex++, nodes: List.from(currentPageNodes)));
            currentPageNodes.clear();
            currentHeight = 0;
            imgHeight = 280.0 + AppSpacing.md;
          }
          currentPageNodes.add(node);
          currentHeight += imgHeight;
          continue;
        }

        final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isEmpty && node.localName != 'hr') continue;

        double bottomPadding = AppSpacing.md;
        double topPadding = 0.0;
        TextStyle style = defaultStyle;
        
        if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(node.localName)) {
          bottomPadding = AppSpacing.lg;
          if (currentPageNodes.isNotEmpty) topPadding = AppSpacing.lg;
          
          double sizeMult = 1.2;
          if (node.localName == 'h1') sizeMult = 2.0;
          if (node.localName == 'h2') sizeMult = 1.7;
          if (node.localName == 'h3') sizeMult = 1.4;
          
          style = defaultStyle.copyWith(fontSize: config.fontSize * sizeMult, fontWeight: FontWeight.bold);
        } else if (node.localName == 'hr') {
          bottomPadding = AppSpacing.lg;
          if (currentPageNodes.isNotEmpty) topPadding = AppSpacing.lg;
        }

        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: safeMaxWidth);
        double nodeHeight = textPainter.height + bottomPadding + topPadding;

        if (currentHeight + nodeHeight <= safeMaxHeight) {
          currentPageNodes.add(node);
          currentHeight += nodeHeight;
        } else {
          String remainingText = text;
          
          while (remainingText.isNotEmpty) {
            final availableHeight = safeMaxHeight - currentHeight - bottomPadding;
            final estimatedLineHeight = (style.fontSize ?? 16.0) * (style.height ?? 1.4);

            if (availableHeight < estimatedLineHeight) {
              if (currentPageNodes.isNotEmpty) {
                pages.add(ReaderPage(chapterIndex: chapterIndex, pageIndex: pageIndex++, nodes: List.from(currentPageNodes)));
                currentPageNodes.clear();
                currentHeight = 0;
                continue;
              }
            }

            final painter = TextPainter(
              text: TextSpan(text: remainingText, style: style),
              textDirection: TextDirection.ltr,
            );
            painter.layout(maxWidth: safeMaxWidth);

            if (painter.height <= availableHeight) {
              final chunkNode = dom.Element.tag(node.localName ?? 'p')..text = remainingText;
              currentPageNodes.add(chunkNode);
              currentHeight += painter.height + bottomPadding;
              remainingText = "";
            } else {
              // Fast initial guess using C++ text metrics
              final pos = painter.getPositionForOffset(Offset(safeMaxWidth, availableHeight));
              int splitIndex = pos.offset;

              if (splitIndex <= 0 || splitIndex > remainingText.length) {
                splitIndex = (remainingText.length * 0.5).toInt().clamp(1, remainingText.length);
              }

              // Backtrack to nearest whitespace to prevent cutting words
              int lastSpace = remainingText.lastIndexOf(' ', splitIndex);
              if (lastSpace > 0) {
                splitIndex = lastSpace;
              }

              // Verify and strictly fit within availableHeight
              while (splitIndex > 0) {
                final testText = remainingText.substring(0, splitIndex).trim();
                final testPainter = TextPainter(
                  text: TextSpan(text: testText, style: style),
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: safeMaxWidth);

                if (testPainter.height <= availableHeight) {
                  break;
                }
                splitIndex = remainingText.lastIndexOf(' ', splitIndex - 1);
              }

              if (splitIndex <= 0) {
                 // Failsafe if a single word is taller than the page (rare)
                 splitIndex = remainingText.indexOf(' ');
                 if (splitIndex == -1) splitIndex = remainingText.length;
              }

              final chunkText = remainingText.substring(0, splitIndex).trim();
              if (chunkText.isNotEmpty) {
                final chunkNode = dom.Element.tag(node.localName ?? 'p')..text = chunkText;
                currentPageNodes.add(chunkNode);
              }

              pages.add(ReaderPage(chapterIndex: chapterIndex, pageIndex: pageIndex++, nodes: List.from(currentPageNodes)));
              currentPageNodes.clear();
              currentHeight = 0;

              remainingText = remainingText.substring(splitIndex).trim();
            }
          }
        }
      }
    }

    if (currentPageNodes.isNotEmpty) {
      pages.add(ReaderPage(chapterIndex: chapterIndex, pageIndex: pageIndex++, nodes: List.from(currentPageNodes)));
    }

    _chunkCache[cacheKey] = pages;
    if (_chunkCache.length > 50) {
      _chunkCache.remove(_chunkCache.keys.first);
    }

    return pages;
  }
}
