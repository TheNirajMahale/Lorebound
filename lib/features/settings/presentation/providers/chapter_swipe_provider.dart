import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chapter_swipe_config.dart';

import '../../../../core/providers/shared_prefs_provider.dart';

class ChapterSwipeNotifier extends Notifier<ChapterSwipeConfig> {
  static const _keySwipeLeft = 'swipe_left_action';
  static const _keySwipeRight = 'swipe_right_action';

  @override
  ChapterSwipeConfig build() {
    final prefs = ref.watch(sharedPrefsProvider);
    
    final leftIndex = prefs.getInt(_keySwipeLeft);
    final leftAction = leftIndex != null && leftIndex < SwipeAction.values.length
        ? SwipeAction.values[leftIndex]
        : SwipeAction.markAsRead;
        
    final rightIndex = prefs.getInt(_keySwipeRight);
    final rightAction = rightIndex != null && rightIndex < SwipeAction.values.length
        ? SwipeAction.values[rightIndex]
        : SwipeAction.markAsUnread;

    return ChapterSwipeConfig(
      swipeLeft: leftAction,
      swipeRight: rightAction,
    );
  }

  void updateSwipeLeft(SwipeAction action) {
    state = state.copyWith(swipeLeft: action);
    ref.read(sharedPrefsProvider).setInt(_keySwipeLeft, action.index);
  }

  void updateSwipeRight(SwipeAction action) {
    state = state.copyWith(swipeRight: action);
    ref.read(sharedPrefsProvider).setInt(_keySwipeRight, action.index);
  }
}

final chapterSwipeProvider = NotifierProvider<ChapterSwipeNotifier, ChapterSwipeConfig>(() {
  return ChapterSwipeNotifier();
});
