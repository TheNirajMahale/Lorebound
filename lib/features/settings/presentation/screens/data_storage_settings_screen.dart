import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/export_dialog.dart';
import '../providers/cache_provider.dart';
import 'book_cache_management_screen.dart';

class DataStorageSettingsScreen extends ConsumerWidget {
  const DataStorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheSizeState = ref.watch(cacheControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Storage')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Storage location'),
            subtitle: const Text('/storage/emulated/0/Lorebound'),
            onTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon'), duration: Duration(seconds: 1)),
              );
            },
          ),
          ListTile(
            title: const Text('Manage extracted cache'),
            subtitle: const Text('View and delete fast-loading extracted book data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookCacheManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Clear cache'),
            subtitle: Text(
              cacheSizeState.when(
                data: (size) => 'Free up space used by temporary files ($size)',
                loading: () => 'Calculating cache size...',
                error: (_, _) => 'Free up space used by temporary files (Unknown)',
              ),
            ),
            trailing: cacheSizeState.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                : null,
            onTap: cacheSizeState.isLoading
                ? null
                : () async {
                    await ref.read(cacheControllerProvider.notifier).clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared'), duration: Duration(seconds: 1)),
                      );
                    }
                  },
          ),
          const Divider(),
          ListTile(
            title: const Text('Export library'),
            subtitle: const Text('Save your library data as CSV or JSON'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (context) => const ExportDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}
