import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final unreadCount = book.totalChapters - book.currentChapter;
    final progress = book.totalChapters > 0 ? book.currentChapter / book.totalChapters : 0.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    image: book.coverPath != null && book.coverPath!.isNotEmpty
                        ? DecorationImage(
                            image: FileImage(File(book.coverPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (book.coverPath == null || book.coverPath!.isEmpty)
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
      ),
    );
  }
}
