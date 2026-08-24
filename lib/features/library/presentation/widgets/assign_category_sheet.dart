import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_categories_provider.dart';
import '../../../../core/theme/app_spacing.dart';

class AssignCategorySheet extends ConsumerWidget {
  final List<int> selectedBookIds;

  const AssignCategorySheet({
    super.key,
    required this.selectedBookIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.category),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Assign to Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            categoriesState.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text('No categories created yet.'),
                    ),
                  );
                }
                
                final bookCategoriesState = ref.watch(bookCategoriesProvider);
                
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      
                      return bookCategoriesState.when(
                        data: (bookCategories) {
                          // Find how many selected books have this category
                          int count = 0;
                          for (final bc in bookCategories) {
                            if (bc.categoryId == category.id && selectedBookIds.contains(bc.bookId)) {
                              count++;
                            }
                          }
                          
                          bool? isChecked;
                          if (count == selectedBookIds.length && selectedBookIds.isNotEmpty) {
                            isChecked = true;
                          } else if (count == 0) {
                            isChecked = false;
                          } else {
                            isChecked = null; // Tristate
                          }
                          
                          return CheckboxListTile(
                            tristate: true,
                            value: isChecked,
                            title: Text(category.name),
                            secondary: const Icon(Icons.label_outline),
                            onChanged: (bool? value) {
                              // If value is null, treat it as false (user wants to clear it)
                              final assign = value ?? false;
                              ref.read(categoryManagementProvider.notifier)
                                  .assignBooksToCategory(selectedBookIds, category.id, assign);
                            },
                          );
                        },
                        loading: () => const ListTile(title: Text('Loading...')),
                        error: (_, __) => const ListTile(title: Text('Error')),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('Error: $err')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
  }
}
