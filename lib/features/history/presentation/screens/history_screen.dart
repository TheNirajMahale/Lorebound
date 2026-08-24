import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/history_controller.dart';
import '../../domain/models/history_entry.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _isSearchActive
          ? _buildSearchAppBar(colorScheme)
          : _buildNormalAppBar(context, colorScheme),
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
          return _buildHistoryList(context, filtered, colorScheme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  AppBar _buildNormalAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('History'),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearchActive = true),
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar(ColorScheme colorScheme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearchActive = false;
            _searchController.clear();
            _searchQuery = '';
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search history...',
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
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
            _searchQuery.isEmpty ? 'No reading history' : 'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _searchQuery.isEmpty
                ? 'Books you read will appear here'
                : 'Try a different search term',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<HistoryEntry> entries,
    ColorScheme colorScheme,
  ) {
    // Group entries by date header
    final grouped = <String, List<HistoryEntry>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in entries) {
      final entryDate = DateTime(entry.readAt.year, entry.readAt.month, entry.readAt.day);
      String header;
      if (entryDate == today) {
        header = 'Today';
      } else if (entryDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = '${_monthName(entryDate.month)} ${entryDate.day}, ${entryDate.year}';
      }
      grouped.putIfAbsent(header, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: grouped.length,
      itemBuilder: (context, sectionIndex) {
        final header = grouped.keys.elementAt(sectionIndex);
        final sectionEntries = grouped[header]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
              ),
              child: Text(
                header,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            ...sectionEntries.map((entry) => _buildHistoryTile(context, entry, colorScheme)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    HistoryEntry entry,
    ColorScheme colorScheme,
  ) {
    final timeStr = '${entry.readAt.hour.toString().padLeft(2, '0')}:'
        '${entry.readAt.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: Container(
        width: 40,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          image: entry.bookCoverPath != null && entry.bookCoverPath!.isNotEmpty
              ? DecorationImage(
                  image: FileImage(File(entry.bookCoverPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: entry.bookCoverPath == null || entry.bookCoverPath!.isEmpty
            ? Icon(Icons.book, size: 20, color: colorScheme.onSurfaceVariant)
            : null,
      ),
      title: Text(
        entry.bookTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${entry.chapterTitle ?? 'Chapter ${entry.chapterIndex + 1}'} · $timeStr',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
        onPressed: () {
          ref.read(historyControllerProvider.notifier).deleteEntry(entry.id);
        },
      ),
      onTap: () {
        if (entry.bookFilePath != null) {
          context.push(
            '/reader?bookId=${entry.bookId}'
            '&chapter=${entry.chapterIndex}'
            '&filePath=${Uri.encodeComponent(entry.bookFilePath!)}',
          );
        }
      },
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
            _DeleteOption('Last 15 minutes', () => _deleteByDuration(const Duration(minutes: 15))),
            _DeleteOption('Last hour', () => _deleteByDuration(const Duration(hours: 1))),
            _DeleteOption('Last 24 hours', () => _deleteByDuration(const Duration(hours: 24))),
            _DeleteOption('Last 7 days', () => _deleteByDuration(const Duration(days: 7))),
            _DeleteOption('Last 30 days', () => _deleteByDuration(const Duration(days: 30))),
            _DeleteOption('All time', () => _deleteAll()),
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
                  // Delete everything from the start of the first day to end of last day
                  ref.read(historyControllerProvider.notifier)
                      .deleteHistoryBefore(range.end.add(const Duration(days: 1)));
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

  void _deleteByDuration(Duration duration) {
    Navigator.of(context).pop();
    final cutoff = DateTime.now().subtract(duration);
    ref.read(historyControllerProvider.notifier).deleteHistoryBefore(cutoff);
  }

  void _deleteAll() {
    Navigator.of(context).pop();
    ref.read(historyControllerProvider.notifier).deleteAllHistory();
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
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
