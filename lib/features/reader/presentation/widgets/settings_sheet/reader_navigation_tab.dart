import 'package:flutter/material.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';

class ReaderNavigationTab extends StatelessWidget {
  final String bookTitle;
  final String? author;
  final List<String> chapters;
  final int currentChapterIndex;
  final ValueChanged<int>? onChapterSelected;

  const ReaderNavigationTab({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bookTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.md,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (author != null && author!.isNotEmpty)
                  Text(
                    author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.xs,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${chapters.length} Chapters',
                  style: TextStyle(
                    fontSize: AppTypography.xs,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        Expanded(
          child: chapters.isEmpty
              ? Center(
                  child: Text(
                    'No chapters found.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: chapters.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  itemBuilder: (context, index) {
                    final isCurrent = index == currentChapterIndex;
                    final title = chapters[index];

                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        selected: isCurrent,
                        selectedTileColor: colorScheme.primaryContainer,
                        leading: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: AppTypography.sm,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          title.isEmpty ? 'Chapter ${index + 1}' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTypography.sm,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        trailing: isCurrent
                            ? Icon(
                                Icons.check_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          onChapterSelected?.call(index);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
