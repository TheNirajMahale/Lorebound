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
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
                
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      // For a true implementation we would look up if all/some selected books have this category.
                      // For now, we'll provide a simple tap to assign.
                      return ListTile(
                        leading: const Icon(Icons.label_outline),
                        title: Text(category.name),
                        onTap: () {
                          ref.read(categoryManagementProvider.notifier)
                              .assignBooksToCategory(selectedBookIds, category.id, true);
                          Navigator.of(context).pop();
                        },
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
      ),
    );
  }
}
