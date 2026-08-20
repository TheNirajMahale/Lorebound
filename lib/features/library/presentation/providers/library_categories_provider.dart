import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/local_book_repository.dart';
import '../../data/local/app_database.dart';
import 'package:drift/drift.dart' as drift;

final categoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final repo = ref.watch(localBookRepositoryProvider);
  return repo.watchAllCategories();
});

final bookCategoriesProvider = StreamProvider<List<BookCategoryEntity>>((ref) {
  final repo = ref.watch(localBookRepositoryProvider);
  return repo.watchAllBookCategories();
});

class CategoryManagementController extends Notifier<void> {
  @override
  void build() {}

  Future<void> createCategory(String name) async {
    final repo = ref.read(localBookRepositoryProvider);
    await repo.insertCategory(CategoriesCompanion.insert(name: name));
  }

  Future<void> deleteCategory(int id) async {
    final repo = ref.read(localBookRepositoryProvider);
    await repo.deleteCategory(id);
  }
  
  Future<void> renameCategory(int id, String newName) async {
    final repo = ref.read(localBookRepositoryProvider);
    await repo.renameCategory(id, newName);
  }

  Future<void> assignBooksToCategory(List<int> bookIds, int categoryId, bool assign) async {
    final repo = ref.read(localBookRepositoryProvider);
    await repo.setBooksCategory(bookIds, categoryId, assign);
  }
}

final categoryManagementProvider = NotifierProvider<CategoryManagementController, void>(() {
  return CategoryManagementController();
});
