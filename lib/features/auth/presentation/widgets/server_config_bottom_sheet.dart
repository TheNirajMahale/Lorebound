import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/session_controller.dart';

/// Modal bottom sheet for configuring the self-hosted LoreKeeper API URL.
class ServerConfigBottomSheet extends StatefulWidget {
  final SessionController controller;

  const ServerConfigBottomSheet({
    super.key,
    required this.controller,
  });

  /// Helper to show this bottom sheet cleanly.
  static Future<void> show(BuildContext context, SessionController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) {
        return ServerConfigBottomSheet(controller: controller);
      },
    );
  }

  @override
  State<ServerConfigBottomSheet> createState() => _ServerConfigBottomSheetState();
}

class _ServerConfigBottomSheetState extends State<ServerConfigBottomSheet> {
  late final TextEditingController _urlController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final currentUrl = await widget.controller.getServerUrl();
    if (mounted) {
      setState(() {
        _urlController.text = currentUrl;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await widget.controller.updateServerUrl(url);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server URL set to: $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.dns_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Server URL Configuration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Point to your self-hosted LoreKeeper instance or local network IP.',
            style: TextStyle(
              fontSize: AppTypography.sm,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://192.168.1.50:8080',
                prefixIcon: Icon(Icons.http_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                ActionChip(
                  label: const Text('localhost:8080'),
                  onPressed: () => _urlController.text = 'http://localhost:8080',
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8080 (Emulator)'),
                  onPressed: () => _urlController.text = 'http://10.0.2.2:8080',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Server URL'),
            ),
          ],
        ],
      ),
    );
  }
}
