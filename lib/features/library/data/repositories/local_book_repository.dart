import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';
import 'package:drift/drift.dart' as drift;
final localBookRepositoryProvider = Provider<LocalBookRepository>((ref) {
  return LocalBookRepository(ref.watch(appDatabaseProvider));
});

class LocalBookRepository {
  final AppDatabase _db;

  LocalBookRepository(this._db);

  Future<List<BookEntity>> getAllBooks() {
    return _db.select(_db.books).get();
  }

  Stream<List<BookEntity>> watchAllBooks() {
    return _db.select(_db.books).watch();
  }

  Future<BookEntity?> getBookById(int id) {
    return (_db.select(_db.books)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<BookEntity?> watchBookById(int id) {
    return (_db.select(_db.books)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertBook(BooksCompanion book) {
    return _db.into(_db.books).insert(book);
  }

  Future<bool> updateBook(BookEntity book) {
    return _db.update(_db.books).replace(book);
  }

  Future<int> deleteBook(int id) {
    return (_db.delete(_db.books)..where((t) => t.id.equals(id))).go();
  }

  Future<List<BookEntity>> getBooksByStatus(String status) {
    return (_db.select(_db.books)..where((t) => t.status.equals(status))).get();
  }

  Future<void> updateBookProgress(int id, int currentChapter, String readingPosition) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        currentChapter: drift.Value(currentChapter),
        readingPosition: drift.Value(readingPosition),
        lastReadAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateBookChaptersJson(int id, String chaptersJson, int totalChapters) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        chaptersJson: drift.Value(chaptersJson),
        totalChapters: drift.Value(totalChapters),
      ),
    );
  }

  Future<void> updateBooksStatus(List<int> ids, String status, {int? chapter}) async {
    await (_db.update(_db.books)..where((t) => t.id.isIn(ids))).write(
      BooksCompanion(
        status: drift.Value(status),
        currentChapter: chapter != null ? drift.Value(chapter) : const drift.Value.absent(),
      ),
    );
  }

  Future<void> deleteBooks(List<int> ids) async {
    await (_db.delete(_db.books)..where((t) => t.id.isIn(ids))).go();
  }
}
