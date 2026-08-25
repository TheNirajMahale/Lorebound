import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/local_book_repository.dart';
import '../../domain/models/book.dart';
import '../../../reader/data/services/book_storage_service.dart';
import '../../../reader/data/services/epub_cache_service.dart';

final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, List<Book>>(() {
  return LibraryController();
});

class LibraryController extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final repo = ref.watch(localBookRepositoryProvider);
    final subscription = repo.watchAllBooks().listen((entities) {
      state = AsyncValue.data(entities.map((e) => Book.fromEntity(e)).toList());
    });
    ref.onDispose(() {
      subscription.cancel();
    });
    final entities = await repo.getAllBooks();
    return entities.map((e) => Book.fromEntity(e)).toList();
  }

  Future<void> refresh() async {
    final repo = ref.read(localBookRepositoryProvider);
    final entities = await repo.getAllBooks();
    state = AsyncValue.data(entities.map((e) => Book.fromEntity(e)).toList());
  }
  
  Future<void> deleteBook(int id) async {
    final repo = ref.read(localBookRepositoryProvider);
    final book = await repo.getBookById(id);
    
    // 1. Delete from Database First
    await repo.deleteBook(id);
    
    // 2. Delete Local Files and Caches
    if (book != null) {
      if (book.filePath != null) {
        try {
          final file = File(book.filePath!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (book.coverPath != null) {
        try {
          final file = File(book.coverPath!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      
      final storage = ref.read(bookStorageServiceProvider);
      await storage.deleteBookCache(book.filePath ?? id.toString());
      
      final epubCache = ref.read(epubCacheServiceProvider);
      await epubCache.clearCache(id);
    }
    
    await refresh();
  }

  Future<void> bulkUpdateStatus(List<int> ids, String status, {int? chapter}) async {
    final repo = ref.read(localBookRepositoryProvider);
    await repo.updateBooksStatus(ids, status, chapter: chapter);
    await refresh();
  }

  Future<void> bulkDeleteBooks(List<int> ids) async {
    final repo = ref.read(localBookRepositoryProvider);
    final storage = ref.read(bookStorageServiceProvider);
    final epubCache = ref.read(epubCacheServiceProvider);
    
    // Fetch books to know paths
    final books = <dynamic>[];
    for (final id in ids) {
      final book = await repo.getBookById(id);
      if (book != null) books.add(book);
    }
    
    // 1. Delete from Database First
    await repo.deleteBooks(ids);
    
    // 2. Delete Local Files and Caches
    for (final book in books) {
      if (book.filePath != null) {
        try {
          final file = File(book.filePath!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (book.coverPath != null) {
        try {
          final file = File(book.coverPath!);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      await storage.deleteBookCache(book.filePath ?? book.id.toString());
      await epubCache.clearCache(book.id);
    }
    
    await refresh();
  }
}
