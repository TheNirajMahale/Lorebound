import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../library/data/local/app_database.dart';
import '../../../library/data/local/database_provider.dart';
import '../../domain/models/history_entry.dart';

/// Repository for reading history CRUD operations.
/// Joins ReadingHistories with Books to provide full display data.
class ReadingHistoryRepository {
  final AppDatabase _db;

  ReadingHistoryRepository(this._db);

  /// Get all history entries ordered by most recent first, with book metadata.
  Future<List<HistoryEntry>> getHistory() async {
    final query = _db.select(_db.readingHistories).join([
      innerJoin(
        _db.books,
        _db.books.id.equalsExp(_db.readingHistories.bookId),
      ),
    ]);
    query.orderBy([OrderingTerm.desc(_db.readingHistories.readAt)]);

    final rows = await query.get();
    return rows.map((row) {
      final history = row.readTable(_db.readingHistories);
      final book = row.readTable(_db.books);
      return HistoryEntry(
        id: history.id,
        bookId: history.bookId,
        bookTitle: book.title,
        bookCoverPath: book.coverPath,
        bookAuthor: book.author,
        bookFilePath: book.filePath,
        chapterIndex: history.chapterIndex,
        chapterTitle: history.chapterTitle,
        readAt: history.readAt,
      );
    }).toList();
  }

  /// Add a history entry when a chapter is opened/read.
  Future<void> addHistoryEntry({
    required int bookId,
    required int chapterIndex,
    String? chapterTitle,
  }) async {
    await _db.into(_db.readingHistories).insert(
      ReadingHistoriesCompanion.insert(
        bookId: bookId,
        chapterIndex: chapterIndex,
        chapterTitle: Value(chapterTitle),
        readAt: DateTime.now(),
      ),
    );
  }

  /// Delete all history entries before a given cutoff time.
  Future<void> deleteHistoryBefore(DateTime cutoff) async {
    await (_db.delete(_db.readingHistories)
          ..where((h) => h.readAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  /// Delete a single history entry by ID.
  Future<void> deleteHistoryEntry(int id) async {
    await (_db.delete(_db.readingHistories)..where((h) => h.id.equals(id)))
        .go();
  }

  /// Delete all history entries.
  Future<void> deleteAllHistory() async {
    await _db.delete(_db.readingHistories).go();
  }
}

final readingHistoryRepositoryProvider = Provider<ReadingHistoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReadingHistoryRepository(db);
});
