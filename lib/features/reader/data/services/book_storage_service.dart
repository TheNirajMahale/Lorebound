import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookStorageServiceProvider = Provider<BookStorageService>((ref) {
  return BookStorageService();
});

class BookStorageService {
  Directory? _cacheBaseDir;

  Future<Directory> _getCacheDir(String bookKey) async {
    if (_cacheBaseDir == null) {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheBaseDir = Directory(p.join(docDir.path, 'chapter_cache'));
      if (!await _cacheBaseDir!.exists()) {
        await _cacheBaseDir!.create(recursive: true);
      }
    }
    final sanitizedKey = bookKey.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final bookDir = Directory(p.join(_cacheBaseDir!.path, sanitizedKey));
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  Future<File> _getChapterFile(String bookKey, int chapterIndex) async {
    final dir = await _getCacheDir(bookKey);
    return File(p.join(dir.path, 'ch_$chapterIndex.json'));
  }

  Future<bool> hasChapterOnDisk(String bookKey, int chapterIndex) async {
    try {
      final file = await _getChapterFile(bookKey, chapterIndex);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>?> getChapterFromDisk(String bookKey, int chapterIndex) async {
    try {
      final file = await _getChapterFile(bookKey, chapterIndex);
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(content);
        return {
          'title': decoded['title'] as String? ?? '',
          'htmlContent': decoded['htmlContent'] as String? ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error reading chapter $chapterIndex from disk cache: $e');
    }
    return null;
  }

  Future<void> saveChapterToDisk(
    String bookKey,
    int chapterIndex,
    String title,
    String htmlContent,
  ) async {
    try {
      final file = await _getChapterFile(bookKey, chapterIndex);
      final jsonStr = jsonEncode({
        'title': title,
        'htmlContent': htmlContent,
      });
      await file.writeAsString(jsonStr, flush: true);
    } catch (e) {
      debugPrint('Error saving chapter $chapterIndex to disk cache: $e');
    }
  }

  Future<void> deleteBookCache(String bookKey) async {
    try {
      final dir = await _getCacheDir(bookKey);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting book cache for $bookKey: $e');
    }
  }
}
