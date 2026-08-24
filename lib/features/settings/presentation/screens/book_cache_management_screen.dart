import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../library/data/repositories/local_book_repository.dart';
import '../../../reader/data/services/epub_cache_service.dart';
import '../../../library/data/local/app_database.dart';

class BookCacheInfo {
  final BookEntity book;
  final int cacheSizeBytes;

  BookCacheInfo(this.book, this.cacheSizeBytes);
}

final bookCacheListProvider = FutureProvider.autoDispose<List<BookCacheInfo>>((ref) async {
  final repo = ref.watch(localBookRepositoryProvider);
  final cacheService = ref.watch(epubCacheServiceProvider);

  final books = await repo.getAllBooks();
  List<BookCacheInfo> result = [];

  for (final book in books) {
    final size = await cacheService.getCacheSize(book.id);
    if (size > 0) {
      result.add(BookCacheInfo(book, size));
    }
  }

  // Sort by size descending
  result.sort((a, b) => b.cacheSizeBytes.compareTo(a.cacheSizeBytes));
  return result;
});

class BookCacheManagementScreen extends ConsumerWidget {
  const BookCacheManagementScreen({super.key});

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(bookCacheListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Extracted Cache'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Cache',
            onPressed: () => _confirmClearAll(context, ref),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (cacheList) {
          if (cacheList.isEmpty) {
            return const Center(
              child: Text('No extracted books found.\nOpen a book to extract it for fast loading!'),
            );
          }

          final totalSize = cacheList.fold<int>(0, (sum, item) => sum + item.cacheSizeBytes);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Extracted Size:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      _formatSize(totalSize),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: cacheList.length,
                  itemBuilder: (context, index) {
                    final item = cacheList[index];
                    final hasCover = item.book.coverPath != null && File(item.book.coverPath!).existsSync();
                    return ListTile(
                        leading: hasCover
                            ? Image.file(
                                File(item.book.coverPath!),
                                width: 40,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                              )
                            : const Icon(Icons.book, size: 40),
                      title: Text(item.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_formatSize(item.cacheSizeBytes)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await ref.read(epubCacheServiceProvider).clearCache(item.book.id);
                          ref.invalidate(bookCacheListProvider);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Extracted Cache?'),
        content: const Text(
          'This will delete the fast-loading extracted data for all books to free up storage space. '
          'Your original books will NOT be deleted from the library, but they will take a few seconds to load the next time you open them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(epubCacheServiceProvider).clearAllCache();
              ref.invalidate(bookCacheListProvider);
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }
}
