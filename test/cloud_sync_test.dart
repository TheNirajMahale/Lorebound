import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/library/domain/models/book.dart';
import 'package:lorebound/features/library/data/repositories/cloud_sync_repository.dart';

void main() {
  group('Tri-State Book Storage Lifecycle Tests', () {
    test('Book with backendId == null is localOnly', () {
      final book = Book(
        id: 1,
        title: 'Local Odyssey',
        backendId: null,
        filePath: '/data/user/0/books/odyssey.epub',
      );

      expect(book.storageState, BookStorageState.localOnly);
      expect(book.isLocalOnly, isTrue);
      expect(book.isCloudOnly, isFalse);
      expect(book.isSynced, isFalse);
      expect(book.isDownloaded, isTrue);
    });

    test('Book with backendId != null and filePath == null is cloudOnly', () {
      final book = Book(
        id: 2,
        title: 'Cloud Chronicles',
        backendId: 101,
        filePath: null,
      );

      expect(book.storageState, BookStorageState.cloudOnly);
      expect(book.isCloudOnly, isTrue);
      expect(book.isLocalOnly, isFalse);
      expect(book.isSynced, isFalse);
      expect(book.isDownloaded, isFalse);
    });

    test('Book with backendId != null and filePath != null is synced', () {
      final book = Book(
        id: 3,
        title: 'Synchronized Lore',
        backendId: 202,
        filePath: '/data/user/0/books/lore.epub',
      );

      expect(book.storageState, BookStorageState.synced);
      expect(book.isSynced, isTrue);
      expect(book.isLocalOnly, isFalse);
      expect(book.isCloudOnly, isFalse);
      expect(book.isDownloaded, isTrue);
    });

    test('SyncResult holds counts accurately', () {
      const result = SyncResult(
        insertedStubs: 3,
        updatedBooks: 5,
        deletedStubs: 1,
        linkedBooks: 2,
      );

      expect(result.insertedStubs, 3);
      expect(result.updatedBooks, 5);
      expect(result.deletedStubs, 1);
      expect(result.linkedBooks, 2);
      expect(result.toString(), contains('inserted: 3'));
    });
  });
}
