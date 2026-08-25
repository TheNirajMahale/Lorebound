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
  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      ref.read(categoryManagementProvider.notifier).createCategory(result);
    }
  }

  Future<void> _showRenameCategoryDialog(BuildContext context, int id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName && mounted) {
      ref.read(categoryManagementProvider.notifier).renameCategory(id, result);
    }
  }

  Future<void> _showDeleteCategoryDialog(BuildContext context, int id, String name, List<dynamic> allCategories) async {
    final otherCategories = allCategories.where((c) => c is! Map && c.id != id).toList();
    int? selectedReassignId;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete "$name"?'),
                  if (otherCategories.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Text('What should happen to the books in this category?'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedReassignId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Unassign (keep in "All Books")'),
                        ),
                        ...otherCategories.map((c) {
                          return DropdownMenuItem<int?>(
                            value: (c as dynamic).id as int,
                            child: Text('Reassign to "${c.name}"'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => selectedReassignId = val);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result == true && mounted) {
      ref.read(categoryManagementProvider.notifier).deleteAndReassignCategory(id, selectedReassignId);
    }
  }

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
          final allCategoryPlaceholder = {'id': -1, 'name': 'All Books'};
          combined.insert(safeIndex, allCategoryPlaceholder);
          
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
            itemCount: combined.length,
            onReorderItem: (oldIndex, newIndex) {
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
              final name = isAll ? 'All Books' : category.name;
              
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
                            _showDeleteCategoryDialog(context, id, name, combined);
                          },
                        ),
                    ],
                  ),
                  onTap: isAll ? null : () {
                    _showRenameCategoryDialog(context, id, name);
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
          _showAddCategoryDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
