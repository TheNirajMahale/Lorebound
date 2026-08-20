import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/reader/data/services/epub_parser_service_provider.dart';
import '../../data/repositories/local_book_repository.dart';

final bookChaptersProvider = FutureProvider.family<List<String>, String>((ref, filePath) async {
  final parserService = ref.read(epubParserServiceProvider);
  final repo = ref.read(localBookRepositoryProvider);
  
  // Parse the EPUB
  final epubBook = await parserService.loadBookFromFile(filePath);
  
  final chapters = parserService.flattenChapters(epubBook.Chapters);
  final coverKey = parserService.getCoverKey(epubBook);
  final hasCover = coverKey.isNotEmpty;

  List<String> titles = [];
  if (hasCover) {
    titles.add('Cover');
  }
  
  for (int i = 0; i < chapters.length; i++) {
    final title = chapters[i].Title?.trim();
    if (title != null && title.isNotEmpty) {
      titles.add(title);
    } else {
      titles.add('Chapter ${i + 1}');
    }
  }
  
  // Automatically persist to DB so future opens are 100% instant without parsing
  try {
    final allBooks = await repo.getAllBooks();
    final book = allBooks.cast<dynamic>().firstWhere(
      (b) => b.filePath == filePath,
      orElse: () => null,
    );
    if (book != null) {
      await repo.updateBookChaptersJson(book.id, jsonEncode(titles), chapters.length);
    }
  } catch (_) {}

  return titles;
});
