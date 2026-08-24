import 'package:flutter/material.dart';

enum SwipeAction {
  markAsRead,
  markAsUnread,
  download,
  deleteDownload,
  bookmark,
  none,
}

extension SwipeActionX on SwipeAction {
  String get label {
    switch (this) {
      case SwipeAction.markAsRead:
        return 'Mark as read';
      case SwipeAction.markAsUnread:
        return 'Mark as unread';
      case SwipeAction.download:
        return 'Download';
      case SwipeAction.deleteDownload:
        return 'Delete download';
      case SwipeAction.bookmark:
        return 'Bookmark';
      case SwipeAction.none:
        return 'None';
    }
  }

  IconData get icon {
    switch (this) {
      case SwipeAction.markAsRead:
        return Icons.visibility;
      case SwipeAction.markAsUnread:
        return Icons.visibility_off;
      case SwipeAction.download:
        return Icons.download;
      case SwipeAction.deleteDownload:
        return Icons.delete;
      case SwipeAction.bookmark:
        return Icons.bookmark;
      case SwipeAction.none:
        return Icons.do_not_disturb;
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case SwipeAction.markAsRead:
        return scheme.primary;
      case SwipeAction.markAsUnread:
        return scheme.secondary;
      case SwipeAction.download:
        return scheme.tertiary;
      case SwipeAction.deleteDownload:
        return scheme.error;
      case SwipeAction.bookmark:
        return scheme.primaryContainer;
      case SwipeAction.none:
        return scheme.surfaceContainerHighest;
    }
  }
}

class ChapterSwipeConfig {
  final SwipeAction swipeLeft;
  final SwipeAction swipeRight;

  const ChapterSwipeConfig({
    this.swipeLeft = SwipeAction.markAsRead,
    this.swipeRight = SwipeAction.markAsUnread,
  });

  ChapterSwipeConfig copyWith({
    SwipeAction? swipeLeft,
    SwipeAction? swipeRight,
  }) {
    return ChapterSwipeConfig(
      swipeLeft: swipeLeft ?? this.swipeLeft,
      swipeRight: swipeRight ?? this.swipeRight,
    );
  }
}
