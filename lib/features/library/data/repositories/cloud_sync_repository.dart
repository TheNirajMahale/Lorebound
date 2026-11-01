import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../remote/book_remote_data_source.dart';
import 'local_book_repository.dart';

/// Provider for CloudSyncRepository.
final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  final localRepo = ref.watch(localBookRepositoryProvider);
  final remoteDataSource = ref.watch(bookRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return CloudSyncRepository(
    localRepo: localRepo,
    remoteDataSource: remoteDataSource,
    storage: storage,
  );
});

/// Result summary of a catalog diff sync pass.
class SyncResult {
  final int insertedStubs;
  final int updatedBooks;
  final int deletedStubs;
  final int linkedBooks;

  const SyncResult({
    this.insertedStubs = 0,
    this.updatedBooks = 0,
    this.deletedStubs = 0,
    this.linkedBooks = 0,
  });

  @override
  String toString() =>
      'SyncResult(inserted: $insertedStubs, updated: $updatedBooks, deleted: $deletedStubs, linked: $linkedBooks)';
}

/// Service managing remote catalog reconciliation and bidirectional sync.
class CloudSyncRepository {
  final LocalBookRepository localRepo;
  final BookRemoteDataSource remoteDataSource;
  final SecureStorageService storage;

  CloudSyncRepository({
    required this.localRepo,
    required this.remoteDataSource,
    required this.storage,
  });

  /// Performs catalog diff reconciliation between remote LoreKeeper and local Drift SQLite.
  ///
  /// If unauthenticated or token is missing, returns immediately without modifying state.
  Future<SyncResult> syncCatalog() async {
    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      return const SyncResult();
    }

    try {
      final remoteList = await remoteDataSource.getUserBooks();
      final localList = await localRepo.getAllBooks();

      int insertedStubs = 0;
      int updatedBooks = 0;
      int deletedStubs = 0;
      int linkedBooks = 0;

      // Index local books by backendId
      final localByBackendId = <int, BookEntity>{};
      final localWithoutBackendId = <BookEntity>[];

      for (final book in localList) {
        if (book.backendId != null) {
          localByBackendId[book.backendId!] = book;
        } else {
          localWithoutBackendId.add(book);
        }
      }

      final remoteBackendIds = <int>{};

      for (final remote in remoteList) {
        final backendId = (remote['id'] as num?)?.toInt();
        if (backendId == null) continue;
        remoteBackendIds.add(backendId);

        final title = (remote['title'] as String?)?.trim() ?? 'Untitled Book';
        final author = (remote['author'] as String?)?.trim();
        final summary = remote['summary'] as String?;
        final format = (remote['format'] as String?) ?? 'BOOK';
        final totalPages = (remote['totalPages'] as num?)?.toInt();
        final totalChapters = (remote['totalChapters'] as num?)?.toInt() ?? 0;
        final openLibraryWorkId = remote['openLibraryWorkId'] as String?;
        final openLibraryEditionId = remote['openLibraryEditionId'] as String?;
        final status = (remote['status'] as String?) ?? 'WANT_TO_READ';
        final currentPage = (remote['currentPage'] as num?)?.toInt() ?? 0;
        final currentChapter = (remote['currentChapter'] as num?)?.toInt() ?? 0;
        final rating = (remote['rating'] as num?)?.toInt();
        final isFavorite = (remote['isFavorite'] as bool?) ?? false;
        final readingPosition = remote['readingPosition'] as String?;
        final documentId = remote['documentId']?.toString();

        final existing = localByBackendId[backendId];

        if (existing != null) {
          // Reconcile reading progress: latest chapter wins
          final remoteIsAhead = currentChapter > existing.currentChapter;
          final resolvedChapter = remoteIsAhead ? currentChapter : existing.currentChapter;
          final resolvedPage = remoteIsAhead ? currentPage : existing.currentPage;
          final resolvedPosition = remoteIsAhead
              ? (readingPosition ?? existing.readingPosition)
              : existing.readingPosition;

          await localRepo.updateBook(
            existing.copyWith(
              title: title,
              author: drift.Value(author),
              summary: drift.Value(summary),
              format: format,
              totalPages: drift.Value(totalPages),
              totalChapters: totalChapters > 0 ? totalChapters : existing.totalChapters,
              openLibraryWorkId: drift.Value(openLibraryWorkId),
              openLibraryEditionId: drift.Value(openLibraryEditionId),
              status: status,
              currentPage: resolvedPage,
              currentChapter: resolvedChapter,
              rating: drift.Value(rating),
              isFavorite: isFavorite,
              readingPosition: drift.Value(resolvedPosition),
              documentId: drift.Value(documentId ?? existing.documentId),
            ),
          );
          updatedBooks++;
        } else {
          // Check if an existing local unlinked book matches by title + author
          BookEntity? matchedUnlinked;
          for (final unlinked in localWithoutBackendId) {
            final titleMatch = unlinked.title.trim().toLowerCase() == title.toLowerCase();
            final authorMatch = (unlinked.author ?? '').trim().toLowerCase() == (author ?? '').toLowerCase();
            final workIdMatch = openLibraryWorkId != null &&
                unlinked.openLibraryWorkId != null &&
                unlinked.openLibraryWorkId == openLibraryWorkId;

            if (workIdMatch || (titleMatch && authorMatch)) {
              matchedUnlinked = unlinked;
              break;
            }
          }

          if (matchedUnlinked != null) {
            // Link existing local book
            await localRepo.updateBook(
              matchedUnlinked.copyWith(
                backendId: drift.Value(backendId),
                documentId: drift.Value(documentId ?? matchedUnlinked.documentId),
              ),
            );
            localWithoutBackendId.remove(matchedUnlinked);
            linkedBooks++;
          } else {
            // Create cloudOnly stub in SQLite
            await localRepo.insertBook(
              BooksCompanion(
                backendId: drift.Value(backendId),
                title: drift.Value(title),
                author: drift.Value(author),
                summary: drift.Value(summary),
                format: drift.Value(format),
                totalPages: drift.Value(totalPages),
                totalChapters: drift.Value(totalChapters),
                openLibraryWorkId: drift.Value(openLibraryWorkId),
                openLibraryEditionId: drift.Value(openLibraryEditionId),
                status: drift.Value(status),
                currentPage: drift.Value(currentPage),
                currentChapter: drift.Value(currentChapter),
                rating: drift.Value(rating),
                isFavorite: drift.Value(isFavorite),
                readingPosition: drift.Value(readingPosition),
                documentId: drift.Value(documentId),
                filePath: const drift.Value(null), // cloudOnly stub
              ),
            );
            insertedStubs++;
          }
        }
      }

      // Check for local books with backendId that no longer exist on server
      for (final entry in localByBackendId.entries) {
        final backendId = entry.key;
        final localBook = entry.value;

        if (!remoteBackendIds.contains(backendId)) {
          if (localBook.filePath != null && localBook.filePath!.isNotEmpty) {
            // Keep local file intact, detach from backend
            await localRepo.updateBookBackendId(localBook.id, null);
          } else {
            // cloudOnly stub without local file -> safely remove from local database
            await localRepo.deleteBook(localBook.id);
            deletedStubs++;
          }
        }
      }

      return SyncResult(
        insertedStubs: insertedStubs,
        updatedBooks: updatedBooks,
        deletedStubs: deletedStubs,
        linkedBooks: linkedBooks,
      );
    } catch (_) {
      // Offline or network error: preserve existing local state without throwing
      return const SyncResult();
    }
  }

  /// Removes local download while preserving cloud catalog entry.
  Future<void> removeDownload(int bookId) async {
    await localRepo.removeBookDownload(bookId);
  }

  /// Deletes a book both locally and from LoreKeeper cloud.
  Future<void> deleteBookFromLibraryAndCloud(int localId, int? backendId) async {
    // 1. Delete locally
    await localRepo.deleteBook(localId);

    // 2. Delete remotely if linked
    if (backendId != null) {
      try {
        await remoteDataSource.deleteBook(backendId);
      } catch (_) {
        // Silently ignore if remote already deleted or offline
      }
    }
  }
}
