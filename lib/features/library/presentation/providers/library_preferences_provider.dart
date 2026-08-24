import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import 'library_controller.dart';
import 'library_categories_provider.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../settings/presentation/providers/library_ui_provider.dart';

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
  static const _sortTypeKey = 'library_sort_type';
  static const _isAscendingKey = 'library_is_ascending';
  static const _displayModeKey = 'library_display_mode';
  static const _itemsPerRowKey = 'library_items_per_row';
  static const _selectedCategoryKey = 'library_selected_category_id';


  @override
  LibraryPreferences build() {
    final prefs = ref.watch(sharedPrefsProvider);
    
    final sortTypeIndex = prefs.getInt(_sortTypeKey);
    final sortType = sortTypeIndex != null && sortTypeIndex < SortType.values.length
        ? SortType.values[sortTypeIndex]
        : SortType.dateAdded;

    final isAscending = prefs.getBool(_isAscendingKey) ?? false;

    final displayModeIndex = prefs.getInt(_displayModeKey);
    final displayMode = displayModeIndex != null && displayModeIndex < DisplayMode.values.length
        ? DisplayMode.values[displayModeIndex]
        : DisplayMode.comfortableGrid;

    final itemsPerRow = prefs.getInt(_itemsPerRowKey) ?? 2;
    
    final catId = prefs.getInt(_selectedCategoryKey);
    final selectedCategoryId = catId == -1 ? null : catId;

    return LibraryPreferences(
      sortType: sortType,
      isAscending: isAscending,
      displayMode: displayMode,
      itemsPerRow: itemsPerRow,
      selectedCategoryId: selectedCategoryId,
    );
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSortType(SortType sortType, {bool? isAscending}) {
    final newIsAscending = isAscending ?? state.isAscending;
    state = state.copyWith(sortType: sortType, isAscending: newIsAscending);
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setInt(_sortTypeKey, sortType.index);
    prefs.setBool(_isAscendingKey, newIsAscending);
  }

  void toggleSortDirection() {
    final newIsAscending = !state.isAscending;
    state = state.copyWith(isAscending: newIsAscending);
    ref.read(sharedPrefsProvider).setBool(_isAscendingKey, newIsAscending);
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
    ref.read(sharedPrefsProvider).setInt(_displayModeKey, mode.index);
  }

  void updateItemsPerRow(int items) {
    state = state.copyWith(itemsPerRow: items);
    ref.read(sharedPrefsProvider).setInt(_itemsPerRowKey, items);
  }
  
  void updateSelectedCategoryId(int? categoryId) {
    state = state.copyWith(selectedCategoryId: () => categoryId);
    ref.read(sharedPrefsProvider).setInt(_selectedCategoryKey, categoryId ?? -1);
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

final effectiveCategoryIdProvider = Provider<int?>((ref) {
  final preferredId = ref.watch(libraryPreferencesProvider.select((p) => p.selectedCategoryId));
  final showAllCat = ref.watch(showAllCategoryProvider);
  final hiddenCategories = ref.watch(hiddenCategoriesProvider);
  final categoriesState = ref.watch(categoriesProvider);

  if (preferredId == null) {
    if (showAllCat) return null;
  } else {
    if (!hiddenCategories.contains(preferredId)) return preferredId;
  }

  // Fallback: find the first available visible category
  final categories = categoriesState.value ?? [];
  final visibleCategories = categories.where((c) => !hiddenCategories.contains(c.id)).toList();
  if (visibleCategories.isNotEmpty) {
    return visibleCategories.first.id;
  }
  return null; // completely empty or all hidden
});

final filteredLibraryProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksState = ref.watch(libraryControllerProvider);
  final prefs = ref.watch(libraryPreferencesProvider);
  final effectiveCategoryId = ref.watch(effectiveCategoryIdProvider);
  final bookCategoriesState = ref.watch(bookCategoriesProvider);

  return booksState.whenData((books) {
    final bookCategories = bookCategoriesState.value ?? [];

    var filtered = books.where((book) {
      // 0. Category Filter
      if (effectiveCategoryId != null) {
        final isInCat = bookCategories.any((bc) => bc.bookId == book.id && bc.categoryId == effectiveCategoryId);
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
