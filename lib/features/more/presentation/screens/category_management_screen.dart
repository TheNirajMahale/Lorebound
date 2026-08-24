import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../library/presentation/providers/library_categories_provider.dart';
import '../../../settings/presentation/providers/library_ui_provider.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final allCategoryIndex = ref.watch(allCategoryIndexProvider);
    final hiddenCategories = ref.watch(hiddenCategoriesProvider);
    final showAllCat = ref.watch(showAllCategoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesState.when(
        data: (categories) {
          // Combine real categories with fake 'All' category
          final combined = List<dynamic>.from(categories);
          final safeIndex = allCategoryIndex.clamp(0, combined.length);
          
          // Use a custom map or object for the All category since CategoryEntity requires strict args
          final allCategoryPlaceholder = {'id': -1, 'name': 'All'};
          combined.insert(safeIndex, allCategoryPlaceholder);
          
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
            itemCount: combined.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              
              final item = combined.removeAt(oldIndex);
              combined.insert(newIndex, item);
              
              // Find new index of All category
              final newAllIndex = combined.indexWhere((c) => c is Map && c['id'] == -1);
              if (newAllIndex != -1) {
                ref.read(allCategoryIndexProvider.notifier).set(newAllIndex);
              }
              
              // Extract real category IDs in their new order
              final realOrderedIds = combined
                  .where((c) => c is! Map)
                  .map((c) => (c as dynamic).id as int)
                  .toList();
                  
              ref.read(categoryManagementProvider.notifier).reorderCategories(realOrderedIds);
            },
            itemBuilder: (context, index) {
              final category = combined[index];
              final isAll = category is Map && category['id'] == -1;
              final id = isAll ? -1 : category.id;
              final name = isAll ? 'All' : category.name;
              
              final isVisible = isAll ? showAllCat : !hiddenCategories.contains(id);
              
              return Card(
                key: ValueKey(id),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
                  ),
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          if (isAll) {
                            ref.read(showAllCategoryProvider.notifier).toggle();
                          } else {
                            ref.read(hiddenCategoriesProvider.notifier).toggleCategory(id);
                          }
                        },
                      ),
                      if (!isAll)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                    ],
                  ),
                  onTap: isAll ? null : () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 1)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
