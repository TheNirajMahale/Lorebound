import 'dart:convert';
import '../../data/local/app_database.dart';

class Book {
  final int id;
  final int? backendId;
  final String title;
  final String? author;
  final String? summary;
  final String? coverPath;
  final String format;
  final int? totalPages;
  final int totalChapters;
  final String? openLibraryWorkId;
  final String? openLibraryEditionId;
  final String status;
  final int currentPage;
  final int currentChapter;
  final int? rating;
  final bool isFavorite;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? readingPosition;
  final String? documentId;
  final String? filePath;
  final DateTime? lastReadAt;
  final List<String>? cachedChapters;

  Book({
    required this.id,
    this.backendId,
    required this.title,
    this.author,
    this.summary,
    this.coverPath,
    this.format = 'BOOK',
    this.totalPages,
    this.totalChapters = 0,
    this.openLibraryWorkId,
    this.openLibraryEditionId,
    this.status = 'WANT_TO_READ',
    this.currentPage = 0,
    this.currentChapter = 0,
    this.rating,
    this.isFavorite = false,
    this.startedAt,
    this.completedAt,
    this.readingPosition,
    this.documentId,
    this.filePath,
    this.lastReadAt,
    this.cachedChapters,
  });

  factory Book.fromEntity(BookEntity entity) {
    List<String>? parsedChapters;
    if (entity.chaptersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(entity.chaptersJson!);
        parsedChapters = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return Book(
      id: entity.id,
      backendId: entity.backendId,
      title: entity.title,
      author: entity.author,
      summary: entity.summary,
      coverPath: entity.coverPath,
      format: entity.format,
      totalPages: entity.totalPages,
      totalChapters: entity.totalChapters,
      openLibraryWorkId: entity.openLibraryWorkId,
      openLibraryEditionId: entity.openLibraryEditionId,
      status: entity.status,
      currentPage: entity.currentPage,
      currentChapter: entity.currentChapter,
      rating: entity.rating,
      isFavorite: entity.isFavorite,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      readingPosition: entity.readingPosition,
      documentId: entity.documentId,
      filePath: entity.filePath,
      lastReadAt: entity.lastReadAt,
      cachedChapters: parsedChapters,
    );
  }
}
