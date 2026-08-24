import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search settings...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(settingsSearchQueryProvider.notifier).updateQuery(value);
                },
              )
            : const Text('Settings'),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    ref.read(settingsSearchQueryProvider.notifier).updateQuery('');
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching && _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(settingsSearchQueryProvider.notifier).updateQuery('');
              },
            ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults(context, ref, colorScheme)
          : _buildSettingsList(context, colorScheme),
    );
  }

  Widget _buildSearchResults(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final results = ref.watch(settingsSearchProvider);
    final query = ref.watch(settingsSearchQueryProvider);

    if (query.isEmpty) {
      return Center(
        child: Text('Type to search settings', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Text('No results found for "$query"', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return ListTile(
          leading: Icon(entry.icon, color: colorScheme.onSurfaceVariant),
          title: Text(entry.title),
          subtitle: Text(entry.subtitle),
          onTap: () => context.push(entry.route),
        );
      },
    );
  }

  Widget _buildSettingsList(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.palette_outlined, color: colorScheme.onSurfaceVariant),
          title: const Text('Appearance'),
          subtitle: const Text('Theme, date format, language'),
          onTap: () => context.push('/more/settings/appearance'),
        ),
        ListTile(
          leading: Icon(Icons.library_books_outlined, color: colorScheme.onSurfaceVariant),
          title: const Text('Library'),
          subtitle: const Text('Categories, swipe actions'),
          onTap: () => context.push('/more/settings/library'),
        ),
        ListTile(
          leading: Icon(Icons.menu_book_outlined, color: colorScheme.onSurfaceVariant),
          title: const Text('Reader'),
          subtitle: const Text('Bottom card, text alignment, fonts'),
          onTap: () => context.push('/more/settings/reader'),
        ),
        ListTile(
          leading: Icon(Icons.storage_outlined, color: colorScheme.onSurfaceVariant),
          title: const Text('Data and storage'),
          subtitle: const Text('Storage location, cache, export'),
          onTap: () => context.push('/more/settings/data-storage'),
        ),
      ],
    );
  }
}
