import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

@DataClassName('BookEntity')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get backendId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get format => text().withDefault(const Constant('BOOK'))();
  IntColumn get totalPages => integer().nullable()();
  IntColumn get totalChapters => integer().withDefault(const Constant(0))();
  TextColumn get openLibraryWorkId => text().nullable()();
  TextColumn get openLibraryEditionId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('WANT_TO_READ'))();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  IntColumn get currentChapter => integer().withDefault(const Constant(0))();
  IntColumn get rating => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get readingPosition => text().nullable()();
  TextColumn get documentId => text().nullable()();
  
  // Local-only fields
  TextColumn get filePath => text().nullable()();
  DateTimeColumn get lastReadAt => dateTime().nullable()();
  TextColumn get chaptersJson => text().nullable()();
}

@DataClassName('CategoryEntity')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('BookCategoryEntity')
class BookCategories extends Table {
  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  
  @override
  Set<Column> get primaryKey => {bookId, categoryId};
}

@DriftDatabase(tables: [Books, Categories, BookCategories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(categories);
          await m.createTable(bookCategories);
        }
        if (from < 3) {
          await m.addColumn(books, books.chaptersJson);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lorebound_db.sqlite'));



    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
