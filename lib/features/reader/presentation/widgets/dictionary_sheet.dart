import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../data/services/runeglass_service.dart';

/// Modal bottom sheet displaying dictionary definitions and phonetics powered by RuneGlass.
class DictionarySheet extends ConsumerWidget {
  final String word;

  const DictionarySheet({super.key, required this.word});

  static Future<void> show(BuildContext context, String word) {
    final clean = word.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
    if (clean.isEmpty) return Future.value();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => DictionarySheet(word: clean),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runeglass = ref.watch(runeglassServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return FutureBuilder<List<DictionaryWordEntry>>(
          future: runeglass.lookupWord(word),
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.translate_rounded, color: colorScheme.primary, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          word,
                          style: const TextStyle(
                            fontSize: AppTypography.xl,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: _buildBody(context, snapshot, scrollController, colorScheme),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<DictionaryWordEntry>> snapshot,
    ScrollController scrollController,
    ColorScheme colorScheme,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: AppLoadingIndicator());
    }

    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No definition found for "$word"',
                style: const TextStyle(
                  fontSize: AppTypography.md,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ensure the device is connected to your LoreKeeper backend or check the word spelling.',
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final entries = snapshot.data!;

    return ListView.builder(
      controller: scrollController,
      itemCount: entries.length,
      itemBuilder: (context, entryIndex) {
        final entry = entries[entryIndex];
        final phonetics = entry.phonetics.where((p) => p.text != null && p.text!.isNotEmpty).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phonetics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Wrap(
                  spacing: 8,
                  children: phonetics.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        p.text!,
                        style: TextStyle(
                          fontSize: AppTypography.xs,
                          color: colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ...entry.meanings.map((meaning) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        meaning.partOfSpeech.toUpperCase(),
                        style: TextStyle(
                          fontSize: AppTypography.xs,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...meaning.definitions.asMap().entries.map((defEntry) {
                      final idx = defEntry.key + 1;
                      final def = defEntry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$idx. ',
                              style: TextStyle(
                                fontSize: AppTypography.sm,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    def.definition,
                                    style: const TextStyle(fontSize: AppTypography.sm),
                                  ),
                                  if (def.example != null && def.example!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        '“${def.example}”',
                                        style: TextStyle(
                                          fontSize: AppTypography.xs,
                                          fontStyle: FontStyle.italic,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
