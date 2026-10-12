import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../domain/models/reading_statistics.dart';

final readingStatisticsRepositoryProvider = Provider<ReadingStatisticsRepository>((ref) {
  return ReadingStatisticsRepository(ref.watch(appDatabaseProvider));
});

class ReadingStatisticsRepository {
  final AppDatabase _db;

  ReadingStatisticsRepository(this._db);

  /// Records an active reading session in Drift SQLite.
  Future<void> recordReadingSession({
    required int bookId,
    required int chapterIndex,
    required int durationSeconds,
    int wordCount = 0,
  }) async {
    if (durationSeconds < 5) return; // Ignore accidental bounces under 5 seconds
    await _db.into(_db.readingSessions).insert(
      ReadingSessionsCompanion.insert(
        bookId: bookId,
        chapterIndex: chapterIndex,
        durationSeconds: durationSeconds,
        wordCount: drift.Value(wordCount),
        sessionDate: DateTime.now(),
      ),
    );
  }

  /// Identifies books in 'READING' status that have not been opened for 7+ days.
  Future<List<StalledBook>> getStalledBooks({
    Duration stallThreshold = const Duration(days: 7),
  }) async {
    final now = DateTime.now();
    final cutoff = now.subtract(stallThreshold);

    final readingBooks = await (_db.select(_db.books)
          ..where((b) => b.status.equals('READING') & b.lastReadAt.isSmallerOrEqualValue(cutoff))
          ..orderBy([(b) => drift.OrderingTerm.desc(b.lastReadAt)]))
        .get();

    return readingBooks.map((b) {
      final days = b.lastReadAt != null ? now.difference(b.lastReadAt!).inDays : 7;
      return StalledBook(
        book: b,
        daysStalled: days,
        pausedChapter: b.currentChapter,
        totalChapters: b.totalChapters,
        coverPath: b.coverPath,
      );
    }).toList();
  }

  /// Updates status of a stalled book (e.g., move to 'ON_HOLD' or 'DROPPED').
  Future<void> updateBookStatus(int bookId, String newStatus) async {
    await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(status: drift.Value(newStatus)),
    );
  }

  /// Aggregates all reading metrics for the statistics dashboard.
  Future<ReadingStatistics> getAggregatedStatistics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    // 1. All books in library
    final allBooks = await _db.select(_db.books).get();
    int booksReading = 0;
    int booksCompleted = 0;
    int booksWantToRead = 0;

    for (final b in allBooks) {
      if (b.status == 'READING') {
        booksReading++;
      } else if (b.status == 'COMPLETED') {
        booksCompleted++;
      } else {
        booksWantToRead++;
      }
    }

    // 2. All reading history entries
    final history = await (_db.select(_db.readingHistories)
          ..orderBy([(h) => drift.OrderingTerm.asc(h.readAt)]))
        .get();

    // 3. Stalled books (7+ days untouched)
    final stalled = await getStalledBooks();

    // 4. Reading sessions for exact immersion time & WPM
    final sessions = await _db.select(_db.readingSessions).get();

    int totalSessionSeconds = 0;
    int totalWords = 0;
    for (final s in sessions) {
      totalSessionSeconds += s.durationSeconds;
      totalWords += s.wordCount;
    }

    // Fallback immersion estimation for historical entries read before sessions were tracked:
    // estimate ~4.5 minutes (270s) per finished chapter
    int totalReadingSeconds = totalSessionSeconds;
    if (totalReadingSeconds == 0 && history.isNotEmpty) {
      totalReadingSeconds = history.length * 270;
    }

    // 5. Hourly distribution (0..23)
    final hourlyMap = <int, int>{};
    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0;
    }
    for (final h in history) {
      final hour = h.readAt.hour;
      hourlyMap[hour] = (hourlyMap[hour] ?? 0) + 1;
    }
    final hourlyDistribution = hourlyMap.entries
        .map((e) => HourlyActivity(hour: e.key, chapterCount: e.value))
        .toList();

    // 6. Active days this month & 30-day activity
    final uniqueActiveDaysThisMonth = <String>{};
    final dailyChapterMap = <String, int>{};
    final dailySecondsMap = <String, int>{};

    for (final h in history) {
      if (h.readAt.isAfter(monthStart) || h.readAt.isAtSameMomentAs(monthStart)) {
        uniqueActiveDaysThisMonth.add('${h.readAt.year}-${h.readAt.month}-${h.readAt.day}');
      }
      final dateKey = '${h.readAt.year}-${h.readAt.month}-${h.readAt.day}';
      dailyChapterMap[dateKey] = (dailyChapterMap[dateKey] ?? 0) + 1;
    }

    for (final s in sessions) {
      final dateKey = '${s.sessionDate.year}-${s.sessionDate.month}-${s.sessionDate.day}';
      dailySecondsMap[dateKey] = (dailySecondsMap[dateKey] ?? 0) + s.durationSeconds;
    }

    // Build last 30 days array
    final last30Days = <DailyActivity>[];
    for (int i = 29; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final dateKey = '${d.year}-${d.month}-${d.day}';
      last30Days.add(DailyActivity(
        date: d,
        chaptersRead: dailyChapterMap[dateKey] ?? 0,
        secondsRead: dailySecondsMap[dateKey] ?? ((dailyChapterMap[dateKey] ?? 0) * 270),
      ));
    }

    // 7. Streak calculation (consecutive days)
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Check if read today or yesterday for current streak
    final readToday = (dailyChapterMap['${today.year}-${today.month}-${today.day}'] ?? 0) > 0;
    final yesterday = today.subtract(const Duration(days: 1));
    final readYesterday = (dailyChapterMap['${yesterday.year}-${yesterday.month}-${yesterday.day}'] ?? 0) > 0;

    if (readToday || readYesterday) {
      int checkOffset = readToday ? 0 : 1;
      while (true) {
        final d = today.subtract(Duration(days: checkOffset));
        final key = '${d.year}-${d.month}-${d.day}';
        if ((dailyChapterMap[key] ?? 0) > 0) {
          currentStreak++;
          checkOffset++;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak from full 30 days
    for (final day in last30Days) {
      if (day.chaptersRead > 0) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    // 8. WPM & Average minutes per chapter
    double wpm = 0.0;
    if (totalWords > 0 && totalSessionSeconds > 0) {
      wpm = (totalWords / (totalSessionSeconds / 60.0)).clamp(50.0, 800.0);
    } else if (history.isNotEmpty) {
      // Standard calibrated webnovel reader baseline
      wpm = 240.0;
    }

    double avgMinutesPerChapter = 4.5;
    if (history.isNotEmpty && totalReadingSeconds > 0) {
      avgMinutesPerChapter = (totalReadingSeconds / 60.0) / history.length;
    }

    return ReadingStatistics(
      totalReadingSeconds: totalReadingSeconds,
      totalChaptersFinished: history.length,
      activeDaysThisMonth: uniqueActiveDaysThisMonth.length,
      currentStreakDays: currentStreak,
      longestStreakDays: longestStreak,
      wordsPerMinute: double.parse(wpm.toStringAsFixed(1)),
      averageMinutesPerChapter: double.parse(avgMinutesPerChapter.toStringAsFixed(1)),
      hourlyDistribution: hourlyDistribution,
      last30DaysActivity: last30Days,
      stalledBooks: stalled,
      totalBooksInLibrary: allBooks.length,
      booksReading: booksReading,
      booksCompleted: booksCompleted,
      booksWantToRead: booksWantToRead,
    );
  }
}
