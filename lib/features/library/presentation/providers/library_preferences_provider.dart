import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import 'library_controller.dart';
import 'library_categories_provider.dart';

enum SortType { title, lastRead, dateAdded }
enum FilterState { include, exclude, unselected }
enum DisplayMode { compactGrid, comfortableGrid, list }

class LibraryPreferences {
  final String searchQuery;
  final SortType sortType;
  final bool isAscending;
  final FilterState readFilter;
  final FilterState unreadFilter;
  final FilterState startedFilter;
  final DisplayMode displayMode;
  final int itemsPerRow;
  final int? selectedCategoryId; // null means 'All'

  const LibraryPreferences({
    this.searchQuery = '',
    this.sortType = SortType.dateAdded,
    this.isAscending = false,
    this.readFilter = FilterState.unselected,
    this.unreadFilter = FilterState.unselected,
    this.startedFilter = FilterState.unselected,
    this.displayMode = DisplayMode.comfortableGrid,
    this.itemsPerRow = 2,
    this.selectedCategoryId,
  });

  LibraryPreferences copyWith({
    String? searchQuery,
    SortType? sortType,
    bool? isAscending,
    FilterState? readFilter,
    FilterState? unreadFilter,
    FilterState? startedFilter,
    DisplayMode? displayMode,
    int? itemsPerRow,
    int? Function()? selectedCategoryId,
  }) {
    return LibraryPreferences(
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      isAscending: isAscending ?? this.isAscending,
      readFilter: readFilter ?? this.readFilter,
      unreadFilter: unreadFilter ?? this.unreadFilter,
      startedFilter: startedFilter ?? this.startedFilter,
      displayMode: displayMode ?? this.displayMode,
      itemsPerRow: itemsPerRow ?? this.itemsPerRow,
      selectedCategoryId: selectedCategoryId != null ? selectedCategoryId() : this.selectedCategoryId,
    );
  }
}

class LibraryPreferencesNotifier extends Notifier<LibraryPreferences> {
  @override
  LibraryPreferences build() => const LibraryPreferences();

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSortType(SortType sortType, {bool? isAscending}) {
    state = state.copyWith(sortType: sortType, isAscending: isAscending ?? state.isAscending);
  }

  void toggleSortDirection() {
    state = state.copyWith(isAscending: !state.isAscending);
  }

  void updateReadFilter(FilterState filter) {
    state = state.copyWith(readFilter: filter);
  }

  void updateUnreadFilter(FilterState filter) {
    state = state.copyWith(unreadFilter: filter);
  }

  void updateStartedFilter(FilterState filter) {
    state = state.copyWith(startedFilter: filter);
  }

  void updateDisplayMode(DisplayMode mode) {
    state = state.copyWith(displayMode: mode);
  }

  void updateItemsPerRow(int items) {
    state = state.copyWith(itemsPerRow: items);
  }
  
  void updateSelectedCategoryId(int? categoryId) {
    state = state.copyWith(selectedCategoryId: () => categoryId);
  }
  
  void clearFilters() {
    state = state.copyWith(
      readFilter: FilterState.unselected,
      unreadFilter: FilterState.unselected,
      startedFilter: FilterState.unselected,
    );
  }
}

final libraryPreferencesProvider = NotifierProvider<LibraryPreferencesNotifier, LibraryPreferences>(() {
  return LibraryPreferencesNotifier();
});

final filteredLibraryProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksState = ref.watch(libraryControllerProvider);
  final prefs = ref.watch(libraryPreferencesProvider);
  final bookCategoriesState = ref.watch(bookCategoriesProvider);

  return booksState.whenData((books) {
    final bookCategories = bookCategoriesState.value ?? [];

    var filtered = books.where((book) {
      // 0. Category Filter
      if (prefs.selectedCategoryId != null) {
        final isInCat = bookCategories.any((bc) => bc.bookId == book.id && bc.categoryId == prefs.selectedCategoryId);
        if (!isInCat) return false;
      }

      // 1. Search Query
      if (prefs.searchQuery.isNotEmpty) {
        final query = prefs.searchQuery.toLowerCase();
        final matchesTitle = book.title.toLowerCase().contains(query);
        final matchesAuthor = (book.author ?? '').toLowerCase().contains(query);
        if (!matchesTitle && !matchesAuthor) return false;
      }

      // 2. Read Filter
      final isRead = book.status == 'READ' || (book.currentChapter > 0 && book.currentChapter >= book.totalChapters);
      if (prefs.readFilter == FilterState.include && !isRead) return false;
      if (prefs.readFilter == FilterState.exclude && isRead) return false;

      // 3. Unread Filter
      final isUnread = book.status == 'WANT_TO_READ' || (book.currentChapter == 0);
      if (prefs.unreadFilter == FilterState.include && !isUnread) return false;
      if (prefs.unreadFilter == FilterState.exclude && isUnread) return false;

      // 4. Started Filter
      final isStarted = book.currentChapter > 0 && !isRead;
      if (prefs.startedFilter == FilterState.include && !isStarted) return false;
      if (prefs.startedFilter == FilterState.exclude && isStarted) return false;

      return true;
    }).toList();

    // 5. Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (prefs.sortType) {
        case SortType.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortType.lastRead:
          final aDate = a.lastReadAt ?? DateTime(1970);
          final bDate = b.lastReadAt ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
          break;
        case SortType.dateAdded:
          comparison = a.id.compareTo(b.id);
          break;
      }
      return prefs.isAscending ? comparison : -comparison;
    });

    return filtered;
  });
});
