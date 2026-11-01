import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReaderTextSelectionControls extends MaterialTextSelectionControls {
  final bool isExpanded;

  ReaderTextSelectionControls({required this.isExpanded});

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    if (isExpanded) {
      return const SizedBox.shrink();
    }
    return super.buildHandle(context, type, textLineHeight, onTap);
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

void main() {
  testWidgets('ReaderTextSelectionControls suppresses handles when isExpanded is true', (tester) async {
    final controlsExpanded = ReaderTextSelectionControls(isExpanded: true);
    final controlsCollapsed = ReaderTextSelectionControls(isExpanded: false);

    expect(controlsExpanded.getHandleSize(20), Size.zero);
    expect(controlsExpanded.getHandleAnchor(TextSelectionHandleType.left, 20), Offset.zero);
    expect(controlsCollapsed.getHandleSize(20).width, greaterThan(0));
    expect(controlsCollapsed.getHandleAnchor(TextSelectionHandleType.left, 20).dx, greaterThan(0));
  });
}
