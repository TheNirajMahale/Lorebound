import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../remote/book_remote_data_source.dart';
import '../repositories/local_book_repository.dart';

/// Provider for ProgressSyncService.
final progressSyncServiceProvider = Provider<ProgressSyncService>((ref) {
  final localRepo = ref.watch(localBookRepositoryProvider);
  final remoteDataSource = ref.watch(bookRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return ProgressSyncService(
    localRepo: localRepo,
    remoteDataSource: remoteDataSource,
    storage: storage,
  );
});

/// Service managing the durable offline dirty sync queue for reading progress.
class ProgressSyncService {
  static const String dirtyQueueKey = 'pending_sync_book_ids';

  final LocalBookRepository localRepo;
  final BookRemoteDataSource remoteDataSource;
  final SecureStorageService storage;
  bool _isFlushing = false;

  ProgressSyncService({
    required this.localRepo,
    required this.remoteDataSource,
    required this.storage,
  });

  /// Retrieves the persisted list of dirty book IDs awaiting remote sync.
  Future<List<int>> getPendingSyncBookIds() async {
    try {
      final jsonStr = await localRepo.getPreference(dirtyQueueKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Adds a book ID to the durable dirty queue in Drift `UserPreferences`.
  Future<void> markBookDirty(int bookId) async {
    final ids = await getPendingSyncBookIds();
    if (!ids.contains(bookId)) {
      ids.add(bookId);
      await localRepo.setPreference(dirtyQueueKey, jsonEncode(ids));
    }
  }

  /// Removes a book ID from the durable dirty queue after successful push.
  Future<void> _clearBookDirty(int bookId) async {
    final ids = await getPendingSyncBookIds();
    if (ids.remove(bookId)) {
      await localRepo.setPreference(dirtyQueueKey, jsonEncode(ids));
    }
  }

  /// Records reading progress locally in Drift and enqueues durable background sync.
  Future<void> recordProgress({
    required int bookId,
    required int chapterIndex,
    required String readingPosition,
  }) async {
    // 1. Update Drift SQLite locally
    await localRepo.updateBookProgress(bookId, chapterIndex, readingPosition);

    // 2. Mark dirty in durable queue
    await markBookDirty(bookId);

    // 3. Attempt non-blocking background flush
    // Fire-and-forget: does not block reader thread
    flushPendingSyncQueue();
  }

  /// Flushes pending dirty book progress records to LoreKeeper cloud.
  ///
  /// Fails silently without UI disruption if offline or server is unreachable.
  Future<int> flushPendingSyncQueue() async {
    if (_isFlushing) return 0;

    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      // Guest or unauthenticated -> Keep queued until user logs in
      return 0;
    }

    _isFlushing = true;
    int successfullySynced = 0;

    try {
      final dirtyIds = await getPendingSyncBookIds();
      if (dirtyIds.isEmpty) {
        _isFlushing = false;
        return 0;
      }

      for (final bookId in List<int>.from(dirtyIds)) {
        final book = await localRepo.getBookById(bookId);
        if (book == null) {
          await _clearBookDirty(bookId);
          continue;
        }

        if (book.backendId == null) {
          // Local-only book: cannot push progress without backendId
          await _clearBookDirty(bookId);
          continue;
        }

        // Map payload matching Spring Boot BookRequestDTO
        final payload = {
          'title': book.title,
          'author': book.author ?? 'Unknown Author',
          'summary': book.summary,
          'format': book.format,
          'status': book.status,
          'currentChapter': book.currentChapter,
          'currentPage': book.currentPage,
          'readingPosition': book.readingPosition,
          'totalPages': book.totalPages,
          'totalChapters': book.totalChapters,
          'rating': book.rating,
          'isFavorite': book.isFavorite,
          'openLibraryWorkId': book.openLibraryWorkId,
          'openLibraryEditionId': book.openLibraryEditionId,
        };

        try {
          await remoteDataSource.updateBook(book.backendId!, payload);
          await _clearBookDirty(bookId);
          successfullySynced++;
        } catch (_) {
          // Network failure: stop flush loop and retain remaining books in dirty queue
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }

    return successfullySynced;
  }
}
