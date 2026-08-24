import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../reader/presentation/providers/reader_controller.dart';

class ReaderSettingsScreen extends ConsumerWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabOrder = ref.watch(readerTabOrderProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reader')),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Hide book detail'),
              subtitle: const Text('Remove book info from reader bottom card'),
              value: false, // TODO: Wire to provider
              onChanged: (value) {
                // TODO: Wire to provider
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Bottom Card Tab Order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        itemCount: tabOrder.length,
        onReorder: (oldIndex, newIndex) {
          ref.read(readerTabOrderProvider.notifier).reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final tabName = tabOrder[index];
          return Card(
            key: ValueKey(tabName),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4.0),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
              ),
              title: Text(tabName),
            ),
          );
        },
      ),
    );
  }
}
