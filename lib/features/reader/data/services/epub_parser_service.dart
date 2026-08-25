import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epubx/epubx.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'epub_cache_service.dart';

class EpubParserService {
  final EpubCacheService _cacheService;

  EpubParserService(this._cacheService);

  static final Map<String, EpubBook> _bookCache = {};
  static final Map<String, Future<EpubBook>> _parsingTasks = {};

  void cacheBook(String key, EpubBook book) {
    _bookCache[key] = book;
    // Keep max 5 books in memory to prevent OOM
    if (_bookCache.length > 5) {
      _bookCache.remove(_bookCache.keys.first);
    }
  }

  EpubBook? getCachedBook(String key) {
    return _bookCache[key];
  }

  Future<EpubBook> loadBookFromAsset(String assetPath) async {
    if (_bookCache.containsKey(assetPath)) return _bookCache[assetPath]!;
    if (_parsingTasks.containsKey(assetPath)) return await _parsingTasks[assetPath]!;

    final task = _loadAssetTask(assetPath);
    _parsingTasks[assetPath] = task;
    try {
      return await task;
    } finally {
      _parsingTasks.remove(assetPath);
    }
  }

  Future<EpubBook> _loadAssetTask(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final book = await compute(_parseResilientTask, bytes.buffer.asUint8List());
    cacheBook(assetPath, book);
    return book;
  }

  Future<EpubBook> loadBookFromFile(String filePath, {int? bookId}) async {
    if (_bookCache.containsKey(filePath)) return _bookCache[filePath]!;
    if (_parsingTasks.containsKey(filePath)) return await _parsingTasks[filePath]!;

    if (bookId != null) {
      final cachedBook = await _cacheService.loadFromCache(bookId);
      if (cachedBook != null) {
        cacheBook(filePath, cachedBook); // RAM cache
        return cachedBook;
      }
    }

    final task = _loadFileTask(filePath, bookId: bookId);
    _parsingTasks[filePath] = task;
    try {
      return await task;
    } finally {
      _parsingTasks.remove(filePath);
    }
  }

  Future<EpubBook> _loadFileTask(String filePath, {int? bookId}) async {
    final book = await compute(_parseFromFileTask, filePath);
    cacheBook(filePath, book);
    
    if (bookId != null) {
      await _cacheService.saveToCache(bookId, book);
    }
    return book;
  }

  static Future<EpubBook> _parseFromFileTask(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    return _parseResilientTask(bytes);
  }

  /// Parses EPUB bytes with high-performance direct-zip parser and resilient fallback
  static Future<EpubBook> _parseResilientTask(List<int> bytes) async {
    try {
      final directBook = _parseDirectZipTask(bytes);
      if (directBook.Chapters != null && directBook.Chapters!.isNotEmpty) {
        return directBook;
      }
    } catch (_) {}

    try {
      return await EpubReader.readBook(bytes);
    } catch (_) {
      return _parseDirectZipTask(bytes);
    }
  }

  /// 100% resilient direct ZIP extractor that recovers valid chapters and images even from malformed EPUBs
  static EpubBook _parseDirectZipTask(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Locate OPF root file
    String opfPath = '';
    ArchiveFile? containerFile;
    for (var file in archive.files) {
      if (file.name.toLowerCase() == 'meta-inf/container.xml') {
        containerFile = file;
        break;
      }
    }

    if (containerFile != null && containerFile.content != null) {
      try {
        final xmlStr = utf8.decode(containerFile.content as List<int>);
        final doc = XmlDocument.parse(xmlStr);
        final rootfile = doc.findAllElements('rootfile').firstOrNull;
        if (rootfile != null) {
          opfPath = rootfile.getAttribute('full-path') ?? '';
        }
      } catch (_) {}
    }

    if (opfPath.isEmpty) {
      for (var file in archive.files) {
        if (file.name.toLowerCase().endsWith('.opf')) {
          opfPath = file.name;
          break;
        }
      }
    }

    String opfDir = '';
    if (opfPath.contains('/')) {
      opfDir = opfPath.substring(0, opfPath.lastIndexOf('/') + 1);
    }

    ArchiveFile? opfFile;
    for (var file in archive.files) {
      if (file.name == opfPath || file.name.toLowerCase() == opfPath.toLowerCase()) {
        opfFile = file;
        break;
      }
    }

    String title = 'Unknown Title';
    String author = 'Unknown Author';
    Map<String, String> manifest = {};
    List<String> spine = [];

    if (opfFile != null && opfFile.content != null) {
      try {
        final opfStr = utf8.decode(opfFile.content as List<int>);
        final opfDoc = XmlDocument.parse(opfStr);

        // Metadata
        final titleElem =
            opfDoc.findAllElements('dc:title').firstOrNull ??
            opfDoc.findAllElements('title').firstOrNull;
        if (titleElem != null && titleElem.innerText.trim().isNotEmpty) {
          title = titleElem.innerText.trim();
        }

        final authorElem =
            opfDoc.findAllElements('dc:creator').firstOrNull ??
            opfDoc.findAllElements('creator').firstOrNull;
        if (authorElem != null && authorElem.innerText.trim().isNotEmpty) {
          author = authorElem.innerText.trim();
        }

        // Manifest
        for (var item in opfDoc.findAllElements('item')) {
          final id = item.getAttribute('id');
          final href = item.getAttribute('href');
          if (id != null && href != null) {
            manifest[id] = Uri.decodeFull(href);
          }
        }

        // Spine
        for (var itemref in opfDoc.findAllElements('itemref')) {
          final idref = itemref.getAttribute('idref');
          if (idref != null && manifest.containsKey(idref)) {
            spine.add(manifest[idref]!);
          }
        }
      } catch (_) {}
    }

    // Helper to find archive file by href
    ArchiveFile? findFile(String href) {
      final decodedHref = Uri.decodeFull(href);
      final candidatePaths = [
        href,
        decodedHref,
        '$opfDir$href',
        '$opfDir$decodedHref',
        if (href.startsWith('/')) href.substring(1),
        if (decodedHref.startsWith('/')) decodedHref.substring(1),
      ];

      for (var p in candidatePaths) {
        for (var file in archive.files) {
          if (file.name == p || file.name.toLowerCase() == p.toLowerCase()) {
            return file;
          }
        }
      }

      // Fallback: match by basename
      final baseName =
          href.contains('/') ? href.substring(href.lastIndexOf('/') + 1) : href;
      for (var file in archive.files) {
        if (file.name.endsWith('/$baseName') ||
            file.name == baseName ||
            file.name.toLowerCase().endsWith('/${baseName.toLowerCase()}')) {
          return file;
        }
      }
      return null;
    }

    // Chapters
    List<EpubChapter> chapters = [];
    final chapterHrefs =
        spine.isNotEmpty
            ? spine
            : archive.files
                .where(
                  (f) =>
                      f.name.toLowerCase().endsWith('.html') ||
                      f.name.toLowerCase().endsWith('.xhtml'),
                )
                .map((f) => f.name)
                .toList();

    int chapterIndex = 1;
    for (var href in chapterHrefs) {
      final file = findFile(href);
      if (file == null || file.content == null) {
        // Skip missing chapter file without crashing the book!
        continue;
      }

      try {
        final htmlContent = utf8.decode(file.content as List<int>);

        // Extract title from html if possible
        String chTitle = 'Chapter $chapterIndex';
        try {
          final titleMatch = RegExp(
            r'<title[^>]*>([^<]+)<\/title>',
            caseSensitive: false,
          ).firstMatch(htmlContent);
          if (titleMatch != null && titleMatch.group(1)!.trim().isNotEmpty) {
            chTitle = titleMatch.group(1)!.trim();
          } else {
            final hMatch = RegExp(
              r'<h[1-2][^>]*>([^<]+)<\/h[1-2]>',
              caseSensitive: false,
            ).firstMatch(htmlContent);
            if (hMatch != null && hMatch.group(1)!.trim().isNotEmpty) {
              chTitle = hMatch.group(1)!.trim();
            }
          }
        } catch (_) {}

        chapters.add(
          EpubChapter()
            ..Title = chTitle
            ..ContentFileName = file.name
            ..HtmlContent = htmlContent,
        );
        chapterIndex++;
      } catch (_) {}
    }

    // Images
    Map<String, EpubByteContentFile> images = {};
    for (var file in archive.files) {
      final nameLower = file.name.toLowerCase();
      if (nameLower.endsWith('.jpg') ||
          nameLower.endsWith('.jpeg') ||
          nameLower.endsWith('.png') ||
          nameLower.endsWith('.webp') ||
          nameLower.endsWith('.gif') ||
          nameLower.endsWith('.svg')) {
        if (file.content != null) {
          images[file.name] =
              EpubByteContentFile()
                ..FileName = file.name
                ..Content = file.content as List<int>;
        }
      }
    }

    return EpubBook()
      ..Title = title
      ..Author = author
      ..Chapters = chapters
      ..Content = (EpubContent()..Images = images);
  }

  /// Finds the cover or thumbnail image key from various EPUB metadata specifications
  String getCoverKey(EpubBook book) {
    if (book.Content?.Images == null || book.Content!.Images!.isEmpty) {
      return '';
    }

    final images = book.Content!.Images!;

    // 1. Check OPF metadata for <meta name="cover" content="item_id"/>
    try {
      final metaItems = book.Schema?.Package?.Metadata?.MetaItems;
      if (metaItems != null) {
        for (var m in metaItems) {
          if (m.Name?.toLowerCase() == 'cover' && m.Content != null) {
            final manifestItems = book.Schema?.Package?.Manifest?.Items;
            if (manifestItems != null) {
              for (var item in manifestItems) {
                if (item.Id == m.Content && item.Href != null) {
                  for (var key in images.keys) {
                    if (key.endsWith(item.Href!) || item.Href!.endsWith(key)) {
                      return key;
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Check manifest items with properties="cover-image"
    try {
      final manifestItems = book.Schema?.Package?.Manifest?.Items;
      if (manifestItems != null) {
        for (var item in manifestItems) {
          if ((item.Properties?.toLowerCase().contains('cover') ?? false) &&
              item.Href != null) {
            for (var key in images.keys) {
              if (key.endsWith(item.Href!) || item.Href!.endsWith(key)) {
                return key;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3. Keyword heuristic in image filenames
    final keywords = [
      'cover',
      'thumb',
      'thumbnail',
      'front',
      'jacket',
      'titlepage',
      'title_page',
    ];
    for (var keyword in keywords) {
      for (var key in images.keys) {
        if (key.toLowerCase().contains(keyword)) {
          return key;
        }
      }
    }

    // 4. Fallback to the very first image if available
    return images.keys.first;
  }

  /// Extracts a flat list of chapters from potentially nested chapters
  List<EpubChapter> flattenChapters(List<EpubChapter>? chapters) {
    if (chapters == null) return [];

    List<EpubChapter> result = [];
    for (var chapter in chapters) {
      result.add(chapter);
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        result.addAll(flattenChapters(chapter.SubChapters));
      }
    }
    return result;
  }
}
