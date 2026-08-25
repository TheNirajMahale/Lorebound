import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chapter_swipe_config.dart';
import '../providers/chapter_swipe_provider.dart';
import '../../../library/presentation/providers/library_categories_provider.dart';
import '../providers/library_ui_provider.dart';

class LibrarySettingsScreen extends ConsumerWidget {
  const LibrarySettingsScreen({super.key});

  Future<void> _showDefaultCategoryPicker(BuildContext context, WidgetRef ref) async {
    final categoriesState = ref.read(categoriesProvider);
    final defaultId = ref.read(defaultCategoryProvider);

    await categoriesState.whenOrNull(
      data: (categories) async {
        final result = await showDialog<int?>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Default Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioGroup<int?>(
                      groupValue: defaultId,
                      onChanged: (val) => Navigator.pop(context, val),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<int?>(
                            title: const Text('All Books (Default)'),
                            value: null,
                          ),
                          ...categories.map((c) {
                            return RadioListTile<int?>(
                              title: Text(c.name),
                              value: c.id,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, defaultId), // Cancel
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );

        if (result != defaultId) {
          ref.read(defaultCategoryProvider.notifier).set(result);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swipeConfig = ref.watch(chapterSwipeProvider);
    final defaultCatId = ref.watch(defaultCategoryProvider);
    
    // Find the name of the default category
    final categoriesState = ref.watch(categoriesProvider);
    String defaultCatName = 'All Books';
    if (defaultCatId != null) {
      categoriesState.whenData((categories) {
        final match = categories.where((c) => c.id == defaultCatId).firstOrNull;
        if (match != null) defaultCatName = match.name;
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Default category'),
            subtitle: const Text('Where new books are added'),
            trailing: Text(defaultCatName),
            onTap: () {
              _showDefaultCategoryPicker(context, ref);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Chapter Swipe Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Swipe left'),
            subtitle: Text(swipeConfig.swipeLeft.label),
            onTap: () {
              _showActionPicker(
                context,
                'Swipe left',
                swipeConfig.swipeLeft,
                (action) => ref.read(chapterSwipeProvider.notifier).updateSwipeLeft(action),
              );
            },
          ),
          ListTile(
            title: const Text('Swipe right'),
            subtitle: Text(swipeConfig.swipeRight.label),
            onTap: () {
              _showActionPicker(
                context,
                'Swipe right',
                swipeConfig.swipeRight,
                (action) => ref.read(chapterSwipeProvider.notifier).updateSwipeRight(action),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showActionPicker(
    BuildContext context,
    String title,
    SwipeAction currentValue,
    ValueChanged<SwipeAction> onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: RadioGroup<SwipeAction>(
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                onSelected(value);
                Navigator.of(context).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: SwipeAction.values.where((action) => 
                action == SwipeAction.markAsRead || 
                action == SwipeAction.markAsUnread || 
                action == SwipeAction.none
              ).map((action) {
                return RadioListTile<SwipeAction>(
                  title: Text(action.label),
                  value: action,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
