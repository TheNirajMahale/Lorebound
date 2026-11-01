import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(height: 1),

            // Profile section
            const _AccountSection(),
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

/// Login / Profile section matching standard ListTile style of More screen.
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessionAsync = ref.watch(sessionControllerProvider);
    final authState = sessionAsync.value ?? AuthState.guest();
    final isAuthenticated = authState.isAuthenticated;
    final user = authState.user;

    if (isAuthenticated) {
      return ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            (user?.email.isNotEmpty == true) ? user!.email[0].toUpperCase() : 'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          user?.email ?? 'Profile',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Connected to Cloud',
              style: TextStyle(
                fontSize: AppTypography.xs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.logout_rounded, color: colorScheme.error, size: 20),
          tooltip: 'Log Out',
          onPressed: () => _confirmLogout(context, ref),
        ),
        onTap: () => context.push('/auth'),
      );
    }

    return ListTile(
      leading: Icon(
        Icons.account_circle_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
      title: const Text('Profile'),
      subtitle: const Text('Connect to LoreKeeper Cloud'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/auth'),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disconnect from Cloud?'),
          content: const Text(
            'Your local books, offline history, and reading sessions remain intact on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(sessionControllerProvider.notifier).logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out from LoreKeeper'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}

/// Consistent list tile for navigation items in the More screen.
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
