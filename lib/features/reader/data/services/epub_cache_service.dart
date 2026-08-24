import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';

final epubCacheServiceProvider = Provider<EpubCacheService>((ref) {
  return EpubCacheService();
});

class EpubCacheService {
  Future<Directory> _getCacheDir(int bookId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'extracted_cache', 'book_$bookId'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> saveToCache(int bookId, EpubBook book) async {
    try {
      final dir = await _getCacheDir(bookId);

      // 1. Save Chapters to JSON
      final chaptersJson = _chaptersToJson(book.Chapters);
      final bookData = {
        'title': book.Title,
        'author': book.Author,
        'chapters': chaptersJson,
      };
      
      final dataFile = File(p.join(dir.path, 'book_data.json'));
      await dataFile.writeAsString(jsonEncode(bookData));

      // 2. Save Images
      final imagesDir = Directory(p.join(dir.path, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }

      if (book.Content?.Images != null) {
        for (final entry in book.Content!.Images!.entries) {
          final originalKey = entry.key;
          final content = entry.value.Content;
          if (content != null) {
            // Encode key to base64url to safely use as filename (avoids slash issues)
            final safeKey = base64UrlEncode(utf8.encode(originalKey));
            final imgFile = File(p.join(imagesDir.path, safeKey));
            await imgFile.writeAsBytes(content);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to save EPUB cache for book $bookId: $e');
    }
  }

  Future<EpubBook?> loadFromCache(int bookId) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docDir.path, 'extracted_cache', 'book_$bookId'));
      
      if (!await dir.exists()) return null;

      final dataFile = File(p.join(dir.path, 'book_data.json'));
      if (!await dataFile.exists()) return null;

      final jsonStr = await dataFile.readAsString();
      final bookData = jsonDecode(jsonStr) as Map<String, dynamic>;

      final book = EpubBook()
        ..Title = bookData['title'] as String?
        ..Author = bookData['author'] as String?
        ..Chapters = _chaptersFromJson(bookData['chapters'] as List<dynamic>)
        ..Content = EpubContent();

      final imagesDir = Directory(p.join(dir.path, 'images'));
      if (await imagesDir.exists()) {
        final Map<String, EpubByteContentFile> images = {};
        final files = imagesDir.listSync();
        
        for (final file in files) {
          if (file is File) {
            final safeKey = p.basename(file.path);
            try {
              final originalKey = utf8.decode(base64Url.decode(safeKey));
              final content = await file.readAsBytes();
              images[originalKey] = EpubByteContentFile()
                ..FileName = originalKey
                ..Content = content;
            } catch (_) {
              // Ignore invalid files
            }
          }
        }
        book.Content!.Images = images;
      }

      return book;
    } catch (e) {
      debugPrint('Failed to load EPUB cache for book $bookId: $e');
      return null;
    }
  }

  Future<int> getCacheSize(int bookId) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docDir.path, 'extracted_cache', 'book_$bookId'));
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      final files = dir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearCache(int bookId) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docDir.path, 'extracted_cache', 'book_$bookId'));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Failed to clear EPUB cache for book $bookId: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docDir.path, 'extracted_cache'));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Failed to clear all EPUB caches: $e');
    }
  }

  // --- Helpers ---

  List<dynamic> _chaptersToJson(List<EpubChapter>? chapters) {
    if (chapters == null) return [];
    return chapters.map((ch) {
      return {
        'Title': ch.Title,
        'ContentFileName': ch.ContentFileName,
        'HtmlContent': ch.HtmlContent,
        'SubChapters': _chaptersToJson(ch.SubChapters),
      };
    }).toList();
  }

  List<EpubChapter> _chaptersFromJson(List<dynamic> list) {
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return EpubChapter()
        ..Title = map['Title'] as String?
        ..ContentFileName = map['ContentFileName'] as String?
        ..HtmlContent = map['HtmlContent'] as String?
        ..SubChapters = _chaptersFromJson(map['SubChapters'] as List<dynamic>? ?? []);
    }).toList();
  }
}
