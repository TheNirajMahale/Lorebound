import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorebound/core/theme/app_spacing.dart';
import 'package:lorebound/core/theme/app_typography.dart';
import 'settings_sheet/reader_navigation_tab.dart';
import 'settings_sheet/reader_appearance_tab.dart';
import 'settings_sheet/reader_tools_tab.dart';

class ReaderSettingsSheet extends ConsumerStatefulWidget {
  static const tabOrder = ['Navigation', 'Appearance', 'Tools'];

  final List<String> chapters;
  final int currentChapterIndex;
  final ValueChanged<int>? onChapterSelected;
  final String bookTitle;
  final String? author;

  const ReaderSettingsSheet({
    super.key,
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterSelected,
    required this.bookTitle,
    required this.author,
  });

  @override
  ConsumerState<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends ConsumerState<ReaderSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ReaderSettingsSheet.tabOrder.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const tabOrder = ReaderSettingsSheet.tabOrder;

    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Top Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return TabBar(
                      controller: _tabController,
                      indicator: const BoxDecoration(),
                      dividerColor: Colors.transparent,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: AppTypography.xs,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTypography.fontFamily,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: AppTypography.xs,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTypography.fontFamily,
                      ),
                      tabs: tabOrder.map((tabName) {
                        final isSelected = _tabController.index == tabOrder.indexOf(tabName);
                        IconData selectedIcon;
                        IconData unselectedIcon;
                        if (tabName == 'Navigation') {
                          selectedIcon = Icons.menu_book;
                          unselectedIcon = Icons.menu_book_outlined;
                        } else if (tabName == 'Appearance') {
                          selectedIcon = Icons.palette;
                          unselectedIcon = Icons.palette_outlined;
                        } else {
                          selectedIcon = Icons.build;
                          unselectedIcon = Icons.build_outlined;
                        }

                        return Tab(
                          icon: Icon(
                            isSelected ? selectedIcon : unselectedIcon,
                            size: 20,
                          ),
                          text: tabName,
                          height: 48,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Main Tab Content Area
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: tabOrder.map((tabName) {
                    if (tabName == 'Navigation') {
                      return ReaderNavigationTab(
                        bookTitle: widget.bookTitle,
                        author: widget.author,
                        chapters: widget.chapters,
                        currentChapterIndex: widget.currentChapterIndex,
                        onChapterSelected: widget.onChapterSelected,
                      );
                    } else if (tabName == 'Appearance') {
                      return const ReaderAppearanceTab();
                    } else {
                      return const ReaderToolsTab();
                    }
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
