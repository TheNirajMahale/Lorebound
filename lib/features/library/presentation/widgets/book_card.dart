import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/book.dart';
import '../providers/library_selection_provider.dart';

class BookCard extends ConsumerWidget {
  final Book book;

  const BookCard({
    super.key,
    required this.book,
  });

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                margin: EdgeInsets.zero, // M3 Cards have default margin, but we want grid spacing
                elevation: isSelected ? 1 : 0, // slight elevation on select
                child: InkWell(
                  onTap: handleTap,
                  onLongPress: handleLongPress,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (book.coverPath != null && book.coverPath!.isNotEmpty)
                        Image.file(
                          File(book.coverPath!),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: AppTypography.sm,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          child: Center(
                            child: Icon(
                              Icons.check_circle,
                              color: colorScheme.onPrimary,
                              size: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sm,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
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
