import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import '../../domain/models/book.dart';
import '../repositories/local_book_repository.dart';
import '../local/app_database.dart';
import '../../../reader/data/services/epub_parser_service.dart';
import '../../../reader/data/services/epub_parser_service_provider.dart';
import '../../../reader/data/services/epub_cache_service.dart';

import '../../presentation/providers/library_controller.dart';
import '../../presentation/providers/pending_imports_provider.dart';
import '../../presentation/providers/import_results_provider.dart';
import '../../presentation/providers/library_categories_provider.dart';

final epubImportServiceProvider = Provider<EpubImportService>((ref) {
  return EpubImportService(
    ref.watch(localBookRepositoryProvider),
    ref.watch(epubParserServiceProvider),
    ref.watch(epubCacheServiceProvider),
    ref,
  );
});

class EpubImportService {
  final LocalBookRepository _repository;
  final EpubParserService _parserService;
  final EpubCacheService _cacheService;
  final Ref _ref;

  EpubImportService(
      this._repository, this._parserService, this._cacheService, this._ref);

  Future<void> importEpubs(
      List<PlatformFile> files, int? targetCategoryId) async {
    // Add to pending imports
    _ref.read(pendingImportsProvider.notifier).addFiles(files);

    // Process asynchronously so we don't block the caller
    Future.microtask(() async {
      for (final pickedFile in files) {
        final sourcePath = pickedFile.path;
        final fallbackName = pickedFile.name;
        
        if (sourcePath == null) {
          _ref.read(pendingImportsProvider.notifier).removeFile(fallbackName);
          _ref.read(importResultsProvider.notifier).addResult(
            ImportResult(fallbackName, failed: true),
          );
          continue;
        }

        try {
          final sourceFile = File(sourcePath);

          // Parse EPUB metadata
          final epubBook = await _parserService.loadBookFromFile(sourcePath);

          // Defensive extraction
          final title = (epubBook.Title ?? 'Unknown Title').trim();
          final author = (epubBook.Author ?? 'Unknown Author').trim();

          // Duplicate Detection
          final List<Book> existingLibrary =
              _ref.read(libraryControllerProvider).value ??
                  (await _repository.getAllBooks()).map((e) => Book.fromEntity(e)).toList();
                      
          final isDuplicate = existingLibrary.any((b) =>
              b.title.trim().toLowerCase() == title.toLowerCase() &&
              (b.author ?? 'Unknown Author').trim().toLowerCase() == author.toLowerCase());

          if (isDuplicate) {
            _ref.read(importResultsProvider.notifier).addResult(
              ImportResult(title, skippedAsDuplicate: true),
            );
            continue;
          }

          // Get app directories
          final docDir = await getApplicationDocumentsDirectory();
          final booksDir = Directory(p.join(docDir.path, 'books'));
          final coversDir = Directory(p.join(docDir.path, 'covers'));

          if (!await booksDir.exists()) await booksDir.create(recursive: true);
          if (!await coversDir.exists()) await coversDir.create(recursive: true);

          // Generate a unique file name
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'book_$timestamp.epub';
          final destFile = File(p.join(booksDir.path, fileName));

          // Copy epub to local storage
          await sourceFile.copy(destFile.path);

          // Extract Cover Image
          String? coverPath;
          if (epubBook.Content?.Images != null &&
              epubBook.Content!.Images!.isNotEmpty) {
            final coverKey = _parserService.getCoverKey(epubBook);
            if (coverKey.isNotEmpty &&
                epubBook.Content!.Images!.containsKey(coverKey)) {
              final coverImage = epubBook.Content!.Images![coverKey]!;
              if (coverImage.Content != null) {
                final coverFileName = 'cover_$timestamp.jpg';
                final coverFile = File(p.join(coversDir.path, coverFileName));
                await coverFile.writeAsBytes(coverImage.Content!);
                coverPath = coverFile.path;
              }
            }
          }

          // Pre-compute Chapter List JSON
          final flatChapters = _parserService.flattenChapters(epubBook.Chapters);
          final int totalChapters = flatChapters.length;

          List<String> chapterTitles = [];
          final bool hasCover =
              coverPath != null || _parserService.getCoverKey(epubBook).isNotEmpty;

          if (hasCover) {
            chapterTitles.add('Cover');
          }
          for (int i = 0; i < flatChapters.length; i++) {
            final chTitle = flatChapters[i].Title?.trim();
            if (chTitle != null && chTitle.isNotEmpty) {
              chapterTitles.add(chTitle);
            } else {
              chapterTitles.add('Chapter ${i + 1}');
            }
          }
          final String chaptersJsonStr = jsonEncode(chapterTitles);

          // Insert into DB
          final bookId = await _repository.insertBook(BooksCompanion(
            title: drift.Value(title),
            author: drift.Value(author),
            coverPath: drift.Value(coverPath),
            filePath: drift.Value(destFile.path),
            totalChapters: drift.Value(totalChapters),
            chaptersJson: drift.Value(chaptersJsonStr),
            format: const drift.Value('EPUB'),
            status: const drift.Value('WANT_TO_READ'),
          ));

          if (targetCategoryId != null) {
            _ref
                .read(categoryManagementProvider.notifier)
                .assignBooksToCategory([bookId], targetCategoryId, true);
          }

          // Pre-cache the parsed book
          _parserService.cacheBook(destFile.path, epubBook); // RAM
          await _cacheService.saveToCache(bookId, epubBook); // Disk

          _ref.read(importResultsProvider.notifier).addResult(ImportResult(title));

        } catch (e) {
          debugPrint('Failed to import EPUB file $sourcePath: $e');
          _ref.read(importResultsProvider.notifier).addResult(
            ImportResult(sourcePath.split('/').last, failed: true),
          );
        } finally {
          _ref.read(pendingImportsProvider.notifier).removeFile(sourcePath);
          await _ref.read(libraryControllerProvider.notifier).refresh();
        }
      }
    });
  }
}
