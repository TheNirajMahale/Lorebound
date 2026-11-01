import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reader_config.dart';
import '../providers/reader_controller.dart';
import '../providers/reader_selection_controller.dart';

/// Themed custom floating toolbar that replaces the OS default context menu.
///
/// Anchored near the active text selection with buttons for:
/// - **Copy**
/// - **Select All**
class ReaderFloatingToolbar extends StatelessWidget {
  final TextSelectionToolbarAnchors anchors;
  final ReaderConfig config;
  final VoidCallback onCopy;
  final VoidCallback onSelectAll;

  const ReaderFloatingToolbar({
    super.key,
    required this.anchors,
    required this.config,
    required this.onCopy,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final toolbarBg = config.toolbarBackgroundColor;
    final textColor = config.textColor;
    final borderColor = config.borderColor;
    final shadowColor = config.shadowColor;
    final dividerColor = config.dividerColor;

    final anchorBelow = anchors.secondaryAnchor ?? anchors.primaryAnchor;

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchorBelow,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: toolbarBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarActionItem(
                icon: Icons.copy_rounded,
                label: 'Copy',
                textColor: textColor,
                onPressed: onCopy,
              ),
              _ToolbarDivider(color: dividerColor),
              _ToolbarActionItem(
                icon: Icons.select_all_rounded,
                label: 'Select All',
                textColor: textColor,
                onPressed: onSelectAll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reactive wrapper that mounts inside Flutter's `contextMenuBuilder` overlay.
///
/// Automatically hides (`SizedBox.shrink()`) when the selection card is expanded,
/// and reactively restores `ReaderFloatingToolbar` when the card is collapsed back to small.
class ReaderReactiveContextMenu extends ConsumerWidget {
  final SelectableRegionState selectableRegionState;
  final String selectedText;
  final FocusNode focusNode;

  const ReaderReactiveContextMenu({
    super.key,
    required this.selectableRegionState,
    required this.selectedText,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(readerSelectionControllerProvider.select((s) => s.isExpanded));
    if (isExpanded) {
      return const SizedBox.shrink();
    }

    final config = ref.watch(readerControllerProvider).config;
    return ReaderFloatingToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      config: config,
      onCopy: () {
        Clipboard.setData(ClipboardData(text: selectedText));
        selectableRegionState.hideToolbar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onSelectAll: () {
        selectableRegionState.selectAll();
      },
    );
  }
}

class _ToolbarActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onPressed;

  const _ToolbarActionItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.xs,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  final Color color;

  const _ToolbarDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: color,
    );
  }
}

