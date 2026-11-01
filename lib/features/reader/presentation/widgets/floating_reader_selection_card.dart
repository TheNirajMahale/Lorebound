import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/models/reader_config.dart';
import '../../data/services/runeglass_service.dart';
import '../providers/reader_controller.dart';
import '../providers/reader_selection_controller.dart';

/// Themed non-modal floating bottom card for reader text selection and dictionary lookup.
///
/// Floats gracefully over the reader surface:
/// - **Small Card (Peeking):** Clean, unboxed 2-3 line definition preview with English part-of-speech badge.
/// - **Expanded Card (Content-Adaptive):** Full RuneGlass dictionary, definitions, examples, and synonyms,
///   hugging the content dynamically with zero empty bottom whitespace.
class FloatingReaderSelectionCard extends ConsumerStatefulWidget {
  final int? bookId;

  const FloatingReaderSelectionCard({
    super.key,
    this.bookId,
  });

  @override
  ConsumerState<FloatingReaderSelectionCard> createState() =>
      _FloatingReaderSelectionCardState();
}

class _FloatingReaderSelectionCardState
    extends ConsumerState<FloatingReaderSelectionCard> {

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(readerSelectionControllerProvider);
    if (!selectionState.isVisible || selectionState.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final text = selectionState.text;
    final isExpanded = selectionState.isExpanded;
    final isFullScreen = selectionState.isFullScreen;

    final readerConfig = ref.watch(readerControllerProvider).config;
    final cardBg = readerConfig.cardBackgroundColor;
    final cardTextColor = readerConfig.textColor;
    final accentColor = readerConfig.accentColor;
    final borderColor = readerConfig.borderColor;
    final shadowColor = readerConfig.shadowColor;
    final dividerColor = readerConfig.dividerColor;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    final double maxCardHeight;
    if (isFullScreen) {
      maxCardHeight = screenHeight;
    } else if (isExpanded) {
      maxCardHeight = screenHeight * 0.75;
    } else {
      maxCardHeight = 175.0 + bottomPadding;
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -250) {
            // Dragged upwards -> Expand or go Full Screen
            if (!isExpanded) {
              ref.read(readerSelectionControllerProvider.notifier).expand();
            } else if (!isFullScreen) {
              ref.read(readerSelectionControllerProvider.notifier).toggleFullScreen();
            }
          } else if (velocity > 250) {
            // Dragged downwards -> Exit full screen, collapse or dismiss
            if (isFullScreen) {
              ref.read(readerSelectionControllerProvider.notifier).toggleFullScreen();
            } else if (isExpanded) {
              ref.read(readerSelectionControllerProvider.notifier).collapse();
            } else {
              ref.read(readerSelectionControllerProvider.notifier).dismiss();
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            maxHeight: maxCardHeight,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: isFullScreen
                ? BorderRadius.zero
                : const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFullScreen) SizedBox(height: topPadding),
              // Drag Handle
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!isExpanded) {
                    ref.read(readerSelectionControllerProvider.notifier).expand();
                  } else {
                    ref.read(readerSelectionControllerProvider.notifier).toggleFullScreen();
                  }
                },
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardTextColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header Layout:
              // - Small Card: Word title + [Expand, Close]
              // - Expanded Card: Row 1 has [Dictionary] + [Copy, Collapse, Close]; Row 2 has unboxed selected text
              if (!isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 20, color: accentColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: AppTypography.md,
                            fontWeight: FontWeight.bold,
                            color: cardTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Action: Expand
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
                        tooltip: 'Expand',
                        color: cardTextColor.withValues(alpha: 0.8),
                        onPressed: () {
                          ref.read(readerSelectionControllerProvider.notifier).expand();
                        },
                      ),
                      // Action: Close
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Close',
                        color: cardTextColor.withValues(alpha: 0.7),
                        onPressed: () {
                          ref.read(readerSelectionControllerProvider.notifier).dismiss();
                        },
                      ),
                    ],
                  ),
                )
              else ...[
                // Expanded Row 1: Title/Icon on left, [Copy, Collapse, Close] on right
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 20, color: accentColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Dictionary',
                          style: TextStyle(
                            fontSize: AppTypography.md,
                            fontWeight: FontWeight.bold,
                            color: cardTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Action: Copy
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy',
                        color: cardTextColor.withValues(alpha: 0.8),
                        onPressed: () => _copyToClipboard(text),
                      ),
                      // Action: Collapse
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                        tooltip: 'Collapse',
                        color: cardTextColor.withValues(alpha: 0.8),
                        onPressed: () {
                          ref.read(readerSelectionControllerProvider.notifier).collapse();
                        },
                      ),
                      // Action: Close
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Close',
                        color: cardTextColor.withValues(alpha: 0.7),
                        onPressed: () {
                          ref.read(readerSelectionControllerProvider.notifier).dismiss();
                        },
                      ),
                    ],
                  ),
                ),
                // Expanded Row 2: Selected text cleanly unboxed without nested border
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '“$text”',
                      style: TextStyle(
                        fontSize: AppTypography.sm,
                        fontStyle: FontStyle.italic,
                        color: cardTextColor.withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],

              Divider(height: 1, color: dividerColor),

              // Content Area:
              if (isExpanded)
                Flexible(
                  child: _buildDictionaryContent(readerConfig, text),
                )
              else
                InkWell(
                  onTap: () {
                    ref.read(readerSelectionControllerProvider.notifier).expand();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    child: _buildPeekingPreview(readerConfig, text),
                  ),
                ),

              if (bottomPadding > 0) SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  /// Small Card unboxed definition preview with English part-of-speech badge
  Widget _buildPeekingPreview(ReaderConfig config, String text) {
    final runeglass = ref.watch(runeglassServiceProvider);

    return FutureBuilder<List<DictionaryWordEntry>>(
      future: runeglass.lookupWord(text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: config.accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                'Looking up definition...',
                style: TextStyle(
                  fontSize: AppTypography.xs,
                  color: config.secondaryTextColor,
                ),
              ),
            ],
          );
        }

        final entries = snapshot.data;
        if (entries != null && entries.isNotEmpty) {
          final firstEntry = entries.first;
          final firstMeaning = firstEntry.meanings.firstOrNull;
          final partOfSpeech = firstMeaning?.partOfSpeech;
          final firstDef = firstMeaning?.definitions.firstOrNull?.definition;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (partOfSpeech != null && partOfSpeech.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: config.badgeBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        partOfSpeech,
                        style: TextStyle(
                          fontSize: AppTypography.xs,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: config.textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Tap to expand',
                    style: TextStyle(
                      fontSize: AppTypography.xs,
                      color: config.secondaryTextColor,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 16,
                    color: config.secondaryTextColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                firstDef ?? 'Tap to view full dictionary entry and examples.',
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  height: 1.35,
                  color: config.textColor.withValues(alpha: 0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No exact dictionary match',
              style: TextStyle(
                fontSize: AppTypography.xs,
                fontWeight: FontWeight.w600,
                color: config.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to expand for full search and details.',
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: config.textColor.withValues(alpha: 0.85),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  /// Big Card Pure Dictionary View (Content-hugging, zero bottom whitespace)
  Widget _buildDictionaryContent(ReaderConfig config, String text) {
    final runeglass = ref.watch(runeglassServiceProvider);

    return FutureBuilder<List<DictionaryWordEntry>>(
      future: runeglass.lookupWord(text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppLoadingIndicator(color: config.accentColor),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 36, color: config.secondaryTextColor.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No direct dictionary entry for "$text"',
                    style: TextStyle(fontSize: AppTypography.sm, fontWeight: FontWeight.bold, color: config.textColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final entries = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...entry.meanings.map((meaning) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.badgeBackgroundColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: config.borderColor),
                          ),
                          child: Text(
                            meaning.partOfSpeech.toUpperCase(),
                            style: TextStyle(
                              fontSize: AppTypography.xs,
                              fontWeight: FontWeight.bold,
                              color: config.accentColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                                    color: config.secondaryTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        def.definition,
                                        style: TextStyle(fontSize: AppTypography.sm, color: config.textColor),
                                      ),
                                      if (def.example != null && def.example!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            '“${def.example}”',
                                            style: TextStyle(
                                              fontSize: AppTypography.xs,
                                              fontStyle: FontStyle.italic,
                                              color: config.secondaryTextColor,
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
      },
    );
  }
}
