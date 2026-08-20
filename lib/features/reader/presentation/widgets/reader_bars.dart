import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
import '../../domain/models/reader_config.dart';
import 'reader_settings_sheet.dart';

class ReaderTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String chapterTitle;
  final ReaderConfig config;
  final VoidCallback onBackPressed;

  const ReaderTopBar({
    super.key,
    required this.chapterTitle,
    required this.config,
    required this.onBackPressed,
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
      child: Row(
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
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    // We cannot easily use MediaQuery in preferredSize statically, so we define a safe default
    return const Size.fromHeight(kToolbarHeight + AppSpacing.sm);
  }
}

class ReaderBottomBar extends ConsumerStatefulWidget {
  final ReaderConfig config;
  final String progressText;
  final List<String> chapters;
  final int currentChapterIndex;
  final ValueChanged<int>? onChapterSelected;
  final String bookTitle;
  final String? author;

  const ReaderBottomBar({
    super.key,
    required this.config,
    required this.progressText,
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterSelected,
    required this.bookTitle,
    required this.author,
  });

  @override
  ConsumerState<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends ConsumerState<ReaderBottomBar> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimeAndBattery();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateTimeAndBattery());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateTimeAndBattery() async {
    final now = DateTime.now();
    final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    int level = 100;
    try {
      level = await _battery.batteryLevel;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _currentTime = timeStr;
        _batteryLevel = level;
      });
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ReaderSettingsSheet(
        chapters: widget.chapters,
        currentChapterIndex: widget.currentChapterIndex,
        onChapterSelected: widget.onChapterSelected,
        bookTitle: widget.bookTitle,
        author: widget.author,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double safeAreaBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double bottomBezelGap = safeAreaBottom > 0 ? safeAreaBottom : AppSpacing.md;
    const double hudPaddingBottom = AppSpacing.sm;

    // Layout: Left (Time & Battery), Center (Progress), Right (Settings & Import)
    return Container(
      color: widget.config.backgroundColor,
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: bottomBezelGap + hudPaddingBottom,
        top: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Time & Battery
          Row(
            children: [
              Text(
                _currentTime,
                style: TextStyle(
                  color: widget.config.textColor.withValues(alpha: 0.6),
                  fontSize: AppTypography.sm,
                  fontWeight: FontWeight.w500,
                  fontFamily: widget.config.fontFamily,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.battery_std_rounded,
                size: 16.0,
                color: widget.config.textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$_batteryLevel%',
                style: TextStyle(
                  color: widget.config.textColor.withValues(alpha: 0.6),
                  fontSize: AppTypography.sm,
                  fontWeight: FontWeight.w500,
                  fontFamily: widget.config.fontFamily,
                ),
              ),
            ],
          ),
          
          // Center: Progress Text
          if (widget.progressText.isNotEmpty)
            Text(
              widget.progressText,
              style: TextStyle(
                color: widget.config.textColor.withValues(alpha: 0.6),
                fontSize: AppTypography.sm,
                fontWeight: FontWeight.w600,
                fontFamily: widget.config.fontFamily,
              ),
            ),

          // Right: Settings
          Row(
            children: [
              GestureDetector(
                onTap: _showSettings,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(
                    Icons.settings_outlined,
                    size: AppSpacing.lg,
                    color: widget.config.textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
