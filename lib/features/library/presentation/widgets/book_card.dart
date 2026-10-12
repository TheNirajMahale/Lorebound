import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/book.dart';
import '../providers/library_selection_provider.dart';

class BookCard extends ConsumerWidget {
  final Book book;

  const BookCard({
    super.key,
    required this.book,
  });

  Widget _buildFallbackCover(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1.0, (book.title.hashCode.abs() % 360).toDouble(), 0.7, 0.3).toColor(),
            HSLColor.fromAHSL(1.0, ((book.title.hashCode.abs() + 90) % 360).toDouble(), 0.8, 0.4).toColor(),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final unreadCount = book.totalChapters - book.currentChapter;
    final progress = book.totalChapters > 0 ? book.currentChapter / book.totalChapters : 0.0;
    
    final isSelected = ref.watch(librarySelectionProvider.select((s) => s.contains(book.id)));
    final isSelectionMode = ref.watch(librarySelectionProvider.select((s) => s.isNotEmpty));

    void handleTap() {
      if (isSelectionMode) {
        ref.read(librarySelectionProvider.notifier).toggleSelection(book.id);
      } else {
        context.push('/library/book/${book.id}');
      }
    }

    void handleLongPress() {
      ref.read(librarySelectionProvider.notifier).toggleSelection(book.id);
    }

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 3),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.transparent,
            child: InkWell(
              onTap: handleTap,
              onLongPress: handleLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (book.coverPath != null && book.coverPath!.isNotEmpty && File(book.coverPath!).existsSync())
                            Image.file(
                              File(book.coverPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackCover(theme),
                            )
                          else
                            _buildFallbackCover(theme),
                          // Progress bar at the bottom edge of the cover
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.transparent,
                              minHeight: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          ),
                          // Selection Scrim
                          if (isSelected)
                            Container(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusSm)),
                    ),
                    child: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Selection Checkmark Badge
        if (isSelected)
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        // Unread Badge
        if (unreadCount > 0)
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                unreadCount.toString(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
