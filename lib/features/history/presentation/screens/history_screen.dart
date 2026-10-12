import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/history_controller.dart';
import '../../domain/models/history_entry.dart';
import 'package:lorebound/features/settings/presentation/providers/date_format_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedBookId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: !isKeyboardOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isKeyboardOpen) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context, colorScheme),
        body: historyState.when(
          data: (entries) {
            final filtered = _searchQuery.isEmpty
                ? entries
                : entries
                    .where((e) =>
                        e.bookTitle.toLowerCase().contains(_searchQuery) ||
                        (e.chapterTitle?.toLowerCase().contains(_searchQuery) ?? false))
                    .toList();

            if (filtered.isEmpty) {
              return _buildEmptyState(colorScheme);
            }
            return _buildGroupedHistoryList(context, filtered, colorScheme);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      leading: _isSearchActive
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isSearchActive = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
          : null,
      title: _isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search history...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            )
          : const Text('History'),
      centerTitle: false,
      actions: [
        if (_isSearchActive && _searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        if (!_isSearchActive)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearchActive = true),
          ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Clear history...',
          onPressed: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isEmpty ? "You haven't read anything yet" : 'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              _searchQuery.isEmpty
                  ? 'Start by reading an EPUB from your Library'
                  : 'Try a different search term',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedHistoryList(
    BuildContext context,
    List<HistoryEntry> entries,
    ColorScheme colorScheme,
  ) {
    // Group entries by book while preserving recent activity order
    final Map<int, List<HistoryEntry>> bookMap = {};
    for (final entry in entries) {
      bookMap.putIfAbsent(entry.bookId, () => []).add(entry);
    }

    final bookIds = bookMap.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bookIds.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final bookId = bookIds[index];
        final bookEntries = bookMap[bookId]!;
        final latestEntry = bookEntries.first;
        final isExpanded = _expandedBookId == bookId;
        // Limit expanded list to the last 5 entries
        final recentEntries = bookEntries.take(5).toList();

        return Card(
          margin: EdgeInsets.zero,
          elevation: isExpanded ? 1.5 : 0,
          color: isExpanded
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: isExpanded
                ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1)
                : BorderSide.none,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main tile for the book (Header)
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: () {
                  if (latestEntry.bookFilePath != null) {
                    context.push(
                      '/reader?bookId=${latestEntry.bookId}'
                      '&chapter=${latestEntry.chapterIndex}'
                      '&filePath=${Uri.encodeComponent(latestEntry.bookFilePath!)}',
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      // Book Cover thumbnail
                      Container(
                        width: 44,
                        height: 62,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          image: latestEntry.bookCoverPath != null &&
                                  latestEntry.bookCoverPath!.isNotEmpty &&
                                  File(latestEntry.bookCoverPath!).existsSync()
                              ? DecorationImage(
                                  image: FileImage(File(latestEntry.bookCoverPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: latestEntry.bookCoverPath == null ||
                                latestEntry.bookCoverPath!.isEmpty ||
                                !File(latestEntry.bookCoverPath!).existsSync()
                            ? Icon(Icons.book, size: 20, color: colorScheme.onSurfaceVariant)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Book Title & Last Read Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestEntry.bookTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestEntry.chapterTitle ?? 'Chapter ${latestEntry.chapterIndex + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(latestEntry.readAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions: Trash can & Accordion Expand Chevron
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            tooltip: 'Delete book history',
                            onPressed: () => _confirmDeleteBookHistory(
                              context,
                              latestEntry.bookId,
                              latestEntry.bookTitle,
                            ),
                          ),
                          IconButton(
                            icon: AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 24,
                                color: isExpanded
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            tooltip: isExpanded ? 'Collapse' : 'Recent chapters',
                            onPressed: () {
                              setState(() {
                                // Only one book expanded at a time
                                _expandedBookId = isExpanded ? null : bookId;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Accordion List (Last 5 read chapters)
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Recent Chapters',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${recentEntries.length} of ${bookEntries.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentEntries.length,
                  itemBuilder: (context, subIndex) {
                    final subEntry = recentEntries[subIndex];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 0,
                      ),
                      leading: Icon(
                        subIndex == 0 ? Icons.bookmark_added_rounded : Icons.menu_book_rounded,
                        size: 16,
                        color: subIndex == 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        subEntry.chapterTitle ?? 'Chapter ${subEntry.chapterIndex + 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: subIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                          color: subIndex == 0 ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _formatDateTime(subEntry.readAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Remove',
                        onPressed: () {
                          ref.read(historyControllerProvider.notifier).deleteEntry(subEntry.id);
                        },
                      ),
                      onTap: () {
                        if (subEntry.bookFilePath != null) {
                          context.push(
                            '/reader?bookId=${subEntry.bookId}'
                            '&chapter=${subEntry.chapterIndex}'
                            '&filePath=${Uri.encodeComponent(subEntry.bookFilePath!)}',
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteBookHistory(BuildContext context, int bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book History'),
        content: Text('Remove all reading history for "$bookTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(historyControllerProvider.notifier).deleteHistoryForBook(bookId);
              if (_expandedBookId == bookId) {
                setState(() => _expandedBookId = null);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reading history'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DeleteOption('Last 15 minutes', () => _deleteByDuration(context, 'the last 15 minutes', const Duration(minutes: 15))),
            _DeleteOption('Last hour', () => _deleteByDuration(context, 'the last hour', const Duration(hours: 1))),
            _DeleteOption('Last 24 hours', () => _deleteByDuration(context, 'the last 24 hours', const Duration(hours: 24))),
            _DeleteOption('Last 7 days', () => _deleteByDuration(context, 'the last 7 days', const Duration(days: 7))),
            _DeleteOption('Last 30 days', () => _deleteByDuration(context, 'the last 30 days', const Duration(days: 30))),
            _DeleteOption('All time', () => _deleteAll(context)),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: Icon(Icons.date_range, color: colorScheme.primary),
              title: const Text('Custom range...'),
              onTap: () async {
                Navigator.of(context).pop();
                final range = await showDateRangePicker(
                  context: this.context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  _confirmAndDelete(
                    rangeLabel: 'selected date range',
                    onConfirm: () async {
                      final start = DateTime(range.start.year, range.start.month, range.start.day);
                      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
                      await ref.read(historyControllerProvider.notifier).deleteHistoryBetween(start, end);
                    },
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmAndDelete({
    required String rangeLabel,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reading history?'),
        content: Text('Are you sure you want to delete history from $rangeLabel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteByDuration(BuildContext dialogContext, String label, Duration duration) {
    Navigator.of(dialogContext).pop();
    _confirmAndDelete(
      rangeLabel: label,
      onConfirm: () async {
        final cutoff = DateTime.now().subtract(duration);
        await ref.read(historyControllerProvider.notifier).deleteHistoryAfter(cutoff);
      },
    );
  }

  void _deleteAll(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    _confirmAndDelete(
      rangeLabel: 'all time',
      onConfirm: () async {
        await ref.read(historyControllerProvider.notifier).deleteAllHistory();
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return ref.watch(dateFormatProvider).format(dt);
  }
}

class _DeleteOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DeleteOption(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      onTap: onTap,
    );
  }
}
