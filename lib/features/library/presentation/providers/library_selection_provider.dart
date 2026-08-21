import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing selected books in the library screen
final librarySelectionProvider = NotifierProvider<LibrarySelectionNotifier, Set<int>>(() {
  return LibrarySelectionNotifier();
});

class LibrarySelectionNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggleSelection(int bookId) {
    if (state.contains(bookId)) {
      state = {
        for (final id in state)
          if (id != bookId) id
      };
    } else {
      state = {...state, bookId};
    }
  }

  void clearSelection() {
    state = {};
  }

  void selectAll(List<int> allBookIds) {
    state = {...allBookIds};
  }

  void inverseSelection(List<int> allBookIds) {
    final unselected = allBookIds.where((id) => !state.contains(id)).toList();
    state = {...unselected};
  }
}
