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

  // --- Category Methods ---

  Future<List<CategoryEntity>> getAllCategories() {
    return _db.select(_db.categories).get();
  }

  Stream<List<CategoryEntity>> watchAllCategories() {
    return (_db.select(_db.categories)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.sortOrder, mode: drift.OrderingMode.asc)]))
        .watch();
  }

  Stream<List<BookCategoryEntity>> watchAllBookCategories() {
    return _db.select(_db.bookCategories).watch();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  Future<int> renameCategory(int id, String newName) {
    return (_db.update(_db.categories)..where((t) => t.id.equals(id)))
        .write(CategoriesCompanion(name: drift.Value(newName)));
  }

  Future<int> deleteCategory(int id) async {
    // Delete from join table first
    await (_db.delete(_db.bookCategories)..where((t) => t.categoryId.equals(id))).go();
    return (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAndReassignCategory(int oldId, int? newId) async {
    await _db.transaction(() async {
      if (newId != null) {
        final booksInOld = await (_db.select(_db.bookCategories)..where((t) => t.categoryId.equals(oldId))).get();
        for (final entry in booksInOld) {
          await _db.into(_db.bookCategories).insertOnConflictUpdate(
            BookCategoryEntity(bookId: entry.bookId, categoryId: newId)
          );
        }
      }
      await deleteCategory(oldId);
    });
  }

  Future<void> updateCategoryOrder(List<int> orderedIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        final id = orderedIds[i];
        if (id == -1) continue; // Skip fake 'All' category
        await (_db.update(_db.categories)..where((t) => t.id.equals(id)))
            .write(CategoriesCompanion(sortOrder: drift.Value(i)));
      }
    });
  }

  Future<List<CategoryEntity>> getCategoriesForBook(int bookId) async {
    final query = _db.select(_db.bookCategories).join([
      drift.innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.bookCategories.categoryId),
      )
    ])..where(_db.bookCategories.bookId.equals(bookId));

    final results = await query.get();
    return results.map((row) => row.readTable(_db.categories)).toList();
  }

  Future<void> setBooksCategory(List<int> bookIds, int categoryId, bool assign) async {
    await _db.transaction(() async {
      for (final bookId in bookIds) {
        if (assign) {
          await _db.into(_db.bookCategories).insertOnConflictUpdate(
            BookCategoryEntity(bookId: bookId, categoryId: categoryId)
          );
        } else {
          await (_db.delete(_db.bookCategories)
                ..where((t) => t.bookId.equals(bookId) & t.categoryId.equals(categoryId)))
              .go();
        }
      }
    });
  }

  // --- Preferences Methods ---
  
  Future<String?> getPreference(String key) async {
    final pref = await (_db.select(_db.userPreferences)..where((t) => t.key.equals(key))).getSingleOrNull();
    return pref?.value;
  }

  Future<void> setPreference(String key, String value) async {
    await _db.into(_db.userPreferences).insertOnConflictUpdate(
      UserPreferenceEntity(key: key, value: value)
    );
  }
}
