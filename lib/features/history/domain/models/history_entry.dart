/// History domain model — represents a single reading history entry
/// with book metadata joined for display.
class HistoryEntry {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookCoverPath;
  final String? bookAuthor;
  final String? bookFilePath;
  final int chapterIndex;
  final String? chapterTitle;
  final DateTime readAt;

  const HistoryEntry({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookCoverPath,
    this.bookAuthor,
    this.bookFilePath,
    required this.chapterIndex,
    this.chapterTitle,
    required this.readAt,
  });
}
