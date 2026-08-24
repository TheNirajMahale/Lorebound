import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/more_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final downloadedOnly = ref.watch(downloadedOnlyProvider);
    final incognitoMode = ref.watch(incognitoModeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // App logo placeholder — reserved for future branding
            const SizedBox(height: AppSpacing.xl),
            Icon(
              Icons.auto_stories_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lorebound',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),

            // Quick toggles
            SwitchListTile(
              secondary: Icon(
                Icons.cloud_download_outlined,
                color: downloadedOnly ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              title: const Text('Downloaded only'),
              subtitle: const Text('Filters all entries in your library'),
              value: downloadedOnly,
              onChanged: (value) {
                ref.read(downloadedOnlyProvider.notifier).set(value);
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.visibility_off_outlined,
                color: incognitoMode ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              title: const Text('Incognito mode'),
              subtitle: const Text('Pauses reading history'),
              value: incognitoMode,
              onChanged: (value) {
                ref.read(incognitoModeProvider.notifier).set(value);
              },
            ),
            const Divider(height: 1),

            // Navigation items
            _MoreListTile(
              icon: Icons.download_outlined,
              title: 'Downloads',
              onTap: () => context.push('/more/downloads'),
            ),
            _MoreListTile(
              icon: Icons.category_outlined,
              title: 'Categories',
              onTap: () => context.push('/more/categories'),
            ),
            _MoreListTile(
              icon: Icons.query_stats_rounded,
              title: 'Statistics',
              onTap: () => context.push('/more/statistics'),
            ),
            const Divider(height: 1),
            _MoreListTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => context.push('/more/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consistent list tile for navigation items in the More screen.
/// Uses native M3 ListTile — no package needed for this simple pattern.
class _MoreListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MoreListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title),
      onTap: onTap,
    );
  }
}
