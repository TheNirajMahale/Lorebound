import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import '../repositories/local_book_repository.dart';
import '../local/app_database.dart';
import '../../../reader/data/services/epub_parser_service.dart';
import '../../../reader/data/services/epub_parser_service_provider.dart';

final epubImportServiceProvider = Provider<EpubImportService>((ref) {
  return EpubImportService(
    ref.watch(localBookRepositoryProvider),
    ref.watch(epubParserServiceProvider),
  );
});

class EpubImportService {
  final LocalBookRepository _repository;
  final EpubParserService _parserService;

  EpubImportService(this._repository, this._parserService);

  Future<bool> pickAndImportEpub({void Function(int count)? onStartImporting}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return false; // User canceled
      }

      onStartImporting?.call(result.files.length);

      bool anySuccess = false;

      for (final pickedFile in result.files) {
        final sourcePath = pickedFile.path;
        if (sourcePath == null) continue;

        try {
          final sourceFile = File(sourcePath);
          
          // Parse EPUB metadata using the resilient parser!
          final epubBook = await _parserService.loadBookFromFile(sourcePath);

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

          String title = epubBook.Title ?? 'Unknown Title';
          String author = epubBook.Author ?? 'Unknown Author';

          // Extract Cover Image
          String? coverPath;
          if (epubBook.Content?.Images != null && epubBook.Content!.Images!.isNotEmpty) {
            final coverKey = _parserService.getCoverKey(epubBook);
            if (coverKey.isNotEmpty && epubBook.Content!.Images!.containsKey(coverKey)) {
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
          final bool hasCover = coverPath != null || _parserService.getCoverKey(epubBook).isNotEmpty;
          
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
          await _repository.insertBook(
            BooksCompanion(
              title: drift.Value(title),
              author: drift.Value(author),
              coverPath: drift.Value(coverPath),
              filePath: drift.Value(destFile.path),
              totalChapters: drift.Value(totalChapters),
              chaptersJson: drift.Value(chaptersJsonStr),
              format: const drift.Value('EPUB'),
              status: const drift.Value('WANT_TO_READ'),
            )
          );

          // Pre-cache the parsed book so it opens instantly when tapped right after import!
          _parserService.cacheBook(destFile.path, epubBook);

          anySuccess = true;
        } catch (e) {
          debugPrint('Failed to import EPUB file $sourcePath: $e');
        }
      }

      return anySuccess;
    } catch (e) {
      debugPrint('Failed to open file picker: $e');
      return false;
    }
  }
}
