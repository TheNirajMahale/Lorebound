import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_prefs_provider.dart';

class ShowAllCategoryNotifier extends Notifier<bool> {
  static const _key = 'show_all_category';

  @override
  bool build() {
    return ref.watch(sharedPrefsProvider).getBool(_key) ?? true;
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

class AllCategoryIndexNotifier extends Notifier<int> {
  static const _key = 'all_category_index';

  @override
  int build() {
    return ref.watch(sharedPrefsProvider).getInt(_key) ?? 0;
  }

  void set(int value) {
    state = value;
    ref.read(sharedPrefsProvider).setInt(_key, value);
  }
}

class HiddenCategoriesNotifier extends Notifier<List<int>> {
  static const _key = 'hidden_categories';

  @override
  List<int> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final hiddenStrs = prefs.getStringList(_key) ?? [];
    return hiddenStrs.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  void toggleCategory(int categoryId) {
    if (state.contains(categoryId)) {
      state = state.where((id) => id != categoryId).toList();
    } else {
      state = [...state, categoryId];
    }
    
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setStringList(_key, state.map((e) => e.toString()).toList());
  }
}

final showAllCategoryProvider = NotifierProvider<ShowAllCategoryNotifier, bool>(() {
  return ShowAllCategoryNotifier();
});

final allCategoryIndexProvider = NotifierProvider<AllCategoryIndexNotifier, int>(() {
  return AllCategoryIndexNotifier();
});

final hiddenCategoriesProvider = NotifierProvider<HiddenCategoriesNotifier, List<int>>(() {
  return HiddenCategoriesNotifier();
});

class DefaultCategoryNotifier extends Notifier<int?> {
  static const _key = 'default_category_id';

  @override
  int? build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final val = prefs.getInt(_key);
    return val == -1 ? null : val;
  }

  void set(int? categoryId) {
    state = categoryId;
    final prefs = ref.read(sharedPrefsProvider);
    if (categoryId == null) {
      prefs.setInt(_key, -1);
    } else {
      prefs.setInt(_key, categoryId);
    }
  }
}

final defaultCategoryProvider = NotifierProvider<DefaultCategoryNotifier, int?>(() {
  return DefaultCategoryNotifier();
});
