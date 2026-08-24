import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_prefs_provider.dart';

class DownloadedOnlyNotifier extends Notifier<bool> {
  static const _key = 'downloaded_only_mode';

  @override
  bool build() {
    return ref.watch(sharedPrefsProvider).getBool(_key) ?? false;
  }
  
  void toggle() {
    state = !state;
    ref.read(sharedPrefsProvider).setBool(_key, state);
  }
  
  void set(bool value) {
    state = value;
    ref.read(sharedPrefsProvider).setBool(_key, state);
  }
}

final downloadedOnlyProvider = NotifierProvider<DownloadedOnlyNotifier, bool>(() {
  return DownloadedOnlyNotifier();
});

class IncognitoModeNotifier extends Notifier<bool> {
  static const _key = 'incognito_mode';

  @override
  bool build() {
    return ref.watch(sharedPrefsProvider).getBool(_key) ?? false;
  }
  
  void toggle() {
    state = !state;
    ref.read(sharedPrefsProvider).setBool(_key, state);
  }
  
  void set(bool value) {
    state = value;
    ref.read(sharedPrefsProvider).setBool(_key, state);
  }
}

final incognitoModeProvider = NotifierProvider<IncognitoModeNotifier, bool>(() {
  return IncognitoModeNotifier();
});
