import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
import '../../domain/models/reader_config.dart';

class ReaderTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String chapterTitle;
  final ReaderConfig config;
  final VoidCallback onBackPressed;
  final VoidCallback? onSearchTap;
  final bool isSearchOpen;
  final TextEditingController? searchController;
  final VoidCallback? onCloseSearch;
  final ValueChanged<String>? onSearchQueryChanged;
  final int matchCount;
  final int currentMatchIndex;
  final VoidCallback? onNextMatch;
  final VoidCallback? onPrevMatch;

  const ReaderTopBar({
    super.key,
    required this.chapterTitle,
    required this.config,
    required this.onBackPressed,
    this.onSearchTap,
    this.isSearchOpen = false,
    this.searchController,
    this.onCloseSearch,
    this.onSearchQueryChanged,
    this.matchCount = 0,
    this.currentMatchIndex = 0,
    this.onNextMatch,
    this.onPrevMatch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double safeAreaTop = MediaQuery.viewPaddingOf(context).top;
    final double statusBarHeight = safeAreaTop > 0 ? safeAreaTop : AppSpacing.lg;
    const double titleBarPaddingBottom = AppSpacing.sm;

    return Container(
      color: config.backgroundColor,
      padding: EdgeInsets.only(
        top: statusBarHeight,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: titleBarPaddingBottom,
      ),
      child: isSearchOpen
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: AppTypography.md,
                      fontFamily: config.fontFamily,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search in chapter...',
                      hintStyle: TextStyle(
                        color: config.textColor.withValues(alpha: 0.5),
                        fontFamily: config.fontFamily,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onSearchQueryChanged,
                  ),
                ),
                if (matchCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      '${currentMatchIndex + 1}/$matchCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: config.textColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (searchController != null && searchController!.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      '0/0',
                      style: TextStyle(
                        fontSize: 12,
                        color: config.textColor.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (matchCount > 0) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPrevMatch,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: config.textColor.withValues(alpha: 0.8),
                        size: 24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNextMatch,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: config.textColor.withValues(alpha: 0.8),
                        size: 24,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCloseSearch,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.close_rounded,
                      color: config.textColor.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onBackPressed,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: AppSpacing.lg,
                            color: config.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          chapterTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: config.textColor.withValues(alpha: 0.7),
                            fontSize: AppTypography.md,
                            fontWeight: FontWeight.w700,
                            fontFamily: config.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSearchTap != null)
                  GestureDetector(
                    onTap: onSearchTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Icon(
                        Icons.search_rounded,
                        size: AppSpacing.lg,
                        color: config.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight + AppSpacing.sm);
  }
}
