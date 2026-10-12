import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../domain/models/date_format_preference.dart';

class DateFormatNotifier extends Notifier<DateFormatPreference> {
  static const _keyDateFormat = 'setting_date_format';

  @override
  DateFormatPreference build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final savedIndex = prefs.getInt(_keyDateFormat);
    if (savedIndex != null && savedIndex >= 0 && savedIndex < DateFormatPreference.values.length) {
      return DateFormatPreference.values[savedIndex];
    }
    return DateFormatPreference.relative;
  }

  void updatePreference(DateFormatPreference preference) {
    state = preference;
    ref.read(sharedPrefsProvider).setInt(_keyDateFormat, preference.index);
  }
}

final dateFormatProvider = NotifierProvider<DateFormatNotifier, DateFormatPreference>(() {
  return DateFormatNotifier();
});
