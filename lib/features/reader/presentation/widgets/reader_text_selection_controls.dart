import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reader_selection_controller.dart';

/// Custom selection controls for Lorebound reader surfaces.
///
/// Mixes in [TextSelectionHandleControls] so Flutter delegates toolbar presentation
/// completely to [contextMenuBuilder] ([ReaderReactiveContextMenu]) rather than the
/// legacy MaterialTextSelectionControls buildToolbar fallback.
///
/// When the reader selection card is in Big Card or Full Screen mode (`isExpanded: true`),
/// all selection handles (blue draggable teardrop pins) are hidden cleanly without destroying
/// the selection range.
/// When collapsed back to small peeking mode, standard Material handles reactively reappear.
class ReaderTextSelectionControls extends MaterialTextSelectionControls
    with TextSelectionHandleControls {
  final bool isExpanded;

  ReaderTextSelectionControls({this.isExpanded = false});

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    return _ReactiveSelectionHandle(
      type: type,
      textHeight: textHeight,
      onTap: onTap,
      defaultBuilder: super.buildHandle,
      fallbackExpanded: isExpanded,
    );
  }

  @override
  Size getHandleSize(double textLineHeight) {
    if (isExpanded) {
      return Size.zero;
    }
    return super.getHandleSize(textLineHeight);
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    if (isExpanded) {
      return Offset.zero;
    }
    return super.getHandleAnchor(type, textLineHeight);
  }
}

class _ReactiveSelectionHandle extends ConsumerWidget {
  final TextSelectionHandleType type;
  final double textHeight;
  final VoidCallback? onTap;
  final Widget Function(BuildContext, TextSelectionHandleType, double, [VoidCallback?]) defaultBuilder;
  final bool fallbackExpanded;

  const _ReactiveSelectionHandle({
    required this.type,
    required this.textHeight,
    this.onTap,
    required this.defaultBuilder,
    required this.fallbackExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool expanded = fallbackExpanded;
    try {
      expanded = ref.watch(readerSelectionControllerProvider.select((s) => s.isExpanded));
    } catch (_) {
      expanded = fallbackExpanded;
    }

    if (expanded) {
      return const SizedBox.shrink();
    }

    return defaultBuilder(context, type, textHeight, onTap);
  }
}
