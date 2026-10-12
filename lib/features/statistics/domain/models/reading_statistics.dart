import '../../../../core/database/app_database.dart';

class StalledBook {
  final BookEntity book;
  final int daysStalled;
  final int pausedChapter;
  final int totalChapters;
  final String? coverPath;

  const StalledBook({
    required this.book,
    required this.daysStalled,
    required this.pausedChapter,
    required this.totalChapters,
    this.coverPath,
  });
}

class HourlyActivity {
  final int hour; // 0..23
  final int chapterCount;

  const HourlyActivity({
    required this.hour,
    required this.chapterCount,
  });
}

class DailyActivity {
  final DateTime date;
  final int chaptersRead;
  final int secondsRead;

  const DailyActivity({
    required this.date,
    required this.chaptersRead,
    required this.secondsRead,
  });
}

class ReadingStatistics {
  final int totalReadingSeconds;
  final int totalChaptersFinished;
  final int activeDaysThisMonth;
  final int currentStreakDays;
  final int longestStreakDays;
  final double wordsPerMinute;
  final double averageMinutesPerChapter;
  final List<HourlyActivity> hourlyDistribution;
  final List<DailyActivity> last30DaysActivity;
  final List<StalledBook> stalledBooks;
  final int totalBooksInLibrary;
  final int booksReading;
  final int booksCompleted;
  final int booksWantToRead;

  const ReadingStatistics({
    required this.totalReadingSeconds,
    required this.totalChaptersFinished,
    required this.activeDaysThisMonth,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.wordsPerMinute,
    required this.averageMinutesPerChapter,
    required this.hourlyDistribution,
    required this.last30DaysActivity,
    required this.stalledBooks,
    required this.totalBooksInLibrary,
    required this.booksReading,
    required this.booksCompleted,
    required this.booksWantToRead,
  });

  String get formattedTotalTime {
    final hours = totalReadingSeconds ~/ 3600;
    final minutes = (totalReadingSeconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  String get dominantReadingTimeOfDay {
    if (hourlyDistribution.isEmpty) return 'Flexible';
    int morning = 0;   // 6..11
    int afternoon = 0; // 12..17
    int evening = 0;   // 18..21
    int night = 0;     // 22..23, 0..5

    for (final h in hourlyDistribution) {
      if (h.hour >= 6 && h.hour < 12) {
        morning += h.chapterCount;
      } else if (h.hour >= 12 && h.hour < 18) {
        afternoon += h.chapterCount;
      } else if (h.hour >= 18 && h.hour < 22) {
        evening += h.chapterCount;
      } else {
        night += h.chapterCount;
      }
    }

    final maxVal = [morning, afternoon, evening, night].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return 'Flexible';
    if (maxVal == night) return 'Night Owl (10 PM - 6 AM)';
    if (maxVal == evening) return 'Evening Reader (6 PM - 10 PM)';
    if (maxVal == morning) return 'Morning Reader (6 AM - 12 PM)';
    return 'Afternoon Reader (12 PM - 6 PM)';
  }

  String get paceCategory {
    if (wordsPerMinute <= 0) return 'Standard';
    if (wordsPerMinute < 180) return 'Deep Reading';
    if (wordsPerMinute <= 280) return 'Standard Pace';
    if (wordsPerMinute <= 400) return 'Webnovel Flow';
    return 'Fast Scroller';
  }
}
