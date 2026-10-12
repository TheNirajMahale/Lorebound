enum DateFormatPreference {
  relative,
  indian,
  uk,
  us;

  String get label {
    switch (this) {
      case DateFormatPreference.relative:
        return 'Relative (Today, Yesterday)';
      case DateFormatPreference.indian:
        return 'Indian (DD/MM/YYYY 12h)';
      case DateFormatPreference.uk:
        return 'UK / International (DD/MM/YYYY 24h)';
      case DateFormatPreference.us:
        return 'American (MM/DD/YYYY 12h)';
    }
  }

  String format(DateTime dt) {
    final now = DateTime.now();
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampmLower = dt.hour >= 12 ? 'pm' : 'am';
    final ampmUpper = dt.hour >= 12 ? 'PM' : 'AM';
    final hour24 = dt.hour.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();

    switch (this) {
      case DateFormatPreference.relative:
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final date = DateTime(dt.year, dt.month, dt.day);
        final timeStr = '$hour12:$minute $ampmLower';

        if (date == today) {
          return 'Today, $timeStr';
        } else if (date == yesterday) {
          return 'Yesterday, $timeStr';
        } else if (date.year == now.year) {
          return '${dt.day} ${_monthName(dt.month)}, $timeStr';
        } else {
          return '${dt.day} ${_monthName(dt.month)} ${dt.year}, $timeStr';
        }

      case DateFormatPreference.indian:
        return '$day/$month/$year, $hour12:$minute $ampmLower';

      case DateFormatPreference.uk:
        return '$day/$month/$year, $hour24:$minute';

      case DateFormatPreference.us:
        return '$month/$day/$year, $hour12:$minute $ampmUpper';
    }
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
