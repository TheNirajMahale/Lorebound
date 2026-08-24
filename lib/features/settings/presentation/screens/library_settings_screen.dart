import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chapter_swipe_config.dart';
import '../providers/chapter_swipe_provider.dart';

class LibrarySettingsScreen extends ConsumerWidget {
  const LibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swipeConfig = ref.watch(chapterSwipeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Default category'),
            subtitle: const Text('Where new books are added'),
            trailing: const Text('Default'),
            onTap: () {
              // TODO: Implement category dropdown dialog
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: SwipeAction.values.where((action) => 
              action == SwipeAction.markAsRead || 
              action == SwipeAction.markAsUnread || 
              action == SwipeAction.none
            ).map((action) {
              return RadioListTile<SwipeAction>(
                title: Text(action.label),
                value: action,
                groupValue: currentValue,
                onChanged: (value) {
                  if (value != null) {
                    onSelected(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
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
