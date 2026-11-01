import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/local_book_repository.dart';
import '../../domain/models/book.dart';
import '../../../reader/data/services/book_storage_service.dart';
import '../../../reader/data/services/epub_cache_service.dart';

import '../../data/repositories/cloud_sync_repository.dart';
import '../../data/services/vault_service.dart';

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

    // Run background catalog reconciliation if online & authenticated
    _syncCatalogInBackground();

    final entities = await repo.getAllBooks();
    return entities.map((e) => Book.fromEntity(e)).toList();
  }

  Future<void> _syncCatalogInBackground() async {
    try {
      final cloudSync = ref.read(cloudSyncRepositoryProvider);
      await cloudSync.syncCatalog();
    } catch (_) {}
  }

  Future<void> refresh() async {
    try {
      final cloudSync = ref.read(cloudSyncRepositoryProvider);
      await cloudSync.syncCatalog();
    } catch (_) {}

    final repo = ref.read(localBookRepositoryProvider);
    final entities = await repo.getAllBooks();
    state = AsyncValue.data(entities.map((e) => Book.fromEntity(e)).toList());
  }
  
  /// Nuclear deletion: removes local files/caches, deletes local database record,
  /// and deletes from LoreKeeper cloud if linked.
  Future<void> deleteBook(int id, {bool deleteFromCloud = true}) async {
    final repo = ref.read(localBookRepositoryProvider);
    final book = await repo.getBookById(id);
    
    // 1. Delete Local Files and Caches First
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

    // 2. Delete from Database and Cloud
    if (deleteFromCloud && book?.backendId != null) {
      final cloudSync = ref.read(cloudSyncRepositoryProvider);
      await cloudSync.deleteBookFromLibraryAndCloud(id, book?.backendId);
    } else {
      await repo.deleteBook(id);
    }
    
    await refresh();
  }

  /// Removes local EPUB file and cache, keeping the book in the cloud catalog as `cloudOnly`.
  Future<void> removeDownload(int id) async {
    final repo = ref.read(localBookRepositoryProvider);
    final book = await repo.getBookById(id);

    if (book != null && book.filePath != null) {
      try {
        final file = File(book.filePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      final storage = ref.read(bookStorageServiceProvider);
      await storage.deleteBookCache(book.filePath!);

      final epubCache = ref.read(epubCacheServiceProvider);
      await epubCache.clearCache(id);

      final cloudSync = ref.read(cloudSyncRepositoryProvider);
      await cloudSync.removeDownload(id);
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
    
    // 2. Delete Local Files, Caches, and Cloud Records
    final cloudSync = ref.read(cloudSyncRepositoryProvider);
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

      if (book.backendId != null) {
        try {
          await cloudSync.deleteBookFromLibraryAndCloud(book.id, book.backendId);
        } catch (_) {}
      }
    }
    
    await refresh();
  }

  /// Uploads a local book to LoreKeeper cloud vault.
  Future<bool> uploadBook(int id, {void Function(int sent, int total)? onProgress}) async {
    final repo = ref.read(localBookRepositoryProvider);
    final entity = await repo.getBookById(id);
    if (entity == null) return false;
    final book = Book.fromEntity(entity);
    final vaultService = ref.read(vaultServiceProvider);
    final success = await vaultService.uploadBook(book, onProgress: onProgress);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Downloads a cloud-only book from LoreKeeper vault into local device storage.
  Future<bool> downloadBook(int id, {void Function(int received, int total)? onProgress}) async {
    final repo = ref.read(localBookRepositoryProvider);
    final entity = await repo.getBookById(id);
    if (entity == null) return false;
    final book = Book.fromEntity(entity);
    final vaultService = ref.read(vaultServiceProvider);
    final success = await vaultService.downloadBook(book, onProgress: onProgress);
    if (success) {
      await refresh();
    }
    return success;
  }
}
