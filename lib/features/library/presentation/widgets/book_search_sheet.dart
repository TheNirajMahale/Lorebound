import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' as html_parser;
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/book.dart';
import '../../../reader/data/services/epub_parser_service_provider.dart';

class BookSearchResult {
  final int chapterIndex;
  final String chapterTitle;
  final String prefix;
  final String match;
  final String suffix;

  const BookSearchResult({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.prefix,
    required this.match,
    required this.suffix,
  });
}

class BookSearchSheet extends ConsumerStatefulWidget {
  final Book book;

  const BookSearchSheet({super.key, required this.book});

  @override
  ConsumerState<BookSearchSheet> createState() => _BookSearchSheetState();
}

class _BookSearchSheetState extends ConsumerState<BookSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<BookSearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final filePath = widget.book.filePath;
      if (filePath == null || filePath.isEmpty) {
        if (mounted) {
          setState(() {
            _results = [];
            _isSearching = false;
          });
        }
        return;
      }

      final parserService = ref.read(epubParserServiceProvider);
      final epubBook = await parserService.loadBookFromFile(
        filePath,
        bookId: widget.book.id,
      );

      final List<BookSearchResult> matches = [];
      final lowerQuery = trimmed.toLowerCase();
      final chapters = epubBook.Chapters ?? [];

      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        final rawHtml = chapter.HtmlContent;
        if (rawHtml == null || rawHtml.isEmpty) continue;

        final document = html_parser.parse(rawHtml);
        final plainText = document.body?.text ?? '';
        final lowerText = plainText.toLowerCase();

        final chapterName = (chapter.Title != null && chapter.Title!.trim().isNotEmpty)
            ? chapter.Title!.trim()
            : 'Chapter ${i + 1}';

        int startIndex = 0;
        int chapterMatchCount = 0;

        while (true) {
          final matchIndex = lowerText.indexOf(lowerQuery, startIndex);
          if (matchIndex == -1 || chapterMatchCount >= 8) break;

          final prefixStart = (matchIndex - 35).clamp(0, plainText.length);
          final suffixEnd = (matchIndex + trimmed.length + 45).clamp(0, plainText.length);

          final prefix = (prefixStart > 0 ? '…' : '') +
              plainText.substring(prefixStart, matchIndex).replaceAll(RegExp(r'\s+'), ' ');
          final matchedText = plainText.substring(matchIndex, matchIndex + trimmed.length);
          final suffix = plainText
                  .substring(matchIndex + trimmed.length, suffixEnd)
                  .replaceAll(RegExp(r'\s+'), ' ') +
              (suffixEnd < plainText.length ? '…' : '');

          matches.add(
            BookSearchResult(
              chapterIndex: i,
              chapterTitle: chapterName,
              prefix: prefix,
              match: matchedText,
              suffix: suffix,
            ),
          );

          chapterMatchCount++;
          startIndex = matchIndex + trimmed.length;
        }

        if (matches.length >= 100) break;
      }

      if (mounted) {
        setState(() {
          _results = matches;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
          ),
          child: Column(
            children: [
              // Header with Title and Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search_rounded, color: colorScheme.primary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Search in ${widget.book.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search words, names, or quotes...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _performSearch,
                    ),
                  ],
                ),
              ),

              if (_isSearching)
                const LinearProgressIndicator(),

              // Search status or results header
              if (_hasSearched && !_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _results.isEmpty
                          ? 'No matches found'
                          : '${_results.length} match${_results.length == 1 ? '' : 'es'} found',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              // Results List
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          _hasSearched && !_isSearching
                              ? 'Try a different search phrase'
                              : 'Type at least 2 characters to search',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final match = _results[index];

                          return Card(
                            margin: EdgeInsets.zero,
                            color: colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              onTap: () {
                                context.pop();
                                context.push(
                                  '/reader?bookId=${widget.book.id}'
                                  '&chapter=${match.chapterIndex}'
                                  '&filePath=${Uri.encodeComponent(widget.book.filePath ?? '')}',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Chapter badge header
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_stories_outlined,
                                          size: 14,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            match.chapterTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Matched snippet with bold / highlighted keyword
                                    RichText(
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurface,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(text: match.prefix),
                                          TextSpan(
                                            text: match.match,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimaryContainer,
                                              backgroundColor: colorScheme.primaryContainer,
                                            ),
                                          ),
                                          TextSpan(text: match.suffix),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
