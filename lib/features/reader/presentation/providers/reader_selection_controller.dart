import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State representing an active reader text selection and the non-modal floating card.
class ReaderSelectionState {
  final String text;
  final bool isVisible;
  final bool isExpanded;
  final bool isFullScreen;
  final VoidCallback? onSelectAll;
  final VoidCallback? onHideToolbar;
  final VoidCallback? onClearSelection;

  const ReaderSelectionState({
    this.text = '',
    this.isVisible = false,
    this.isExpanded = false,
    this.isFullScreen = false,
    this.onSelectAll,
    this.onHideToolbar,
    this.onClearSelection,
  });

  ReaderSelectionState copyWith({
    String? text,
    bool? isVisible,
    bool? isExpanded,
    bool? isFullScreen,
    VoidCallback? onSelectAll,
    VoidCallback? onHideToolbar,
    VoidCallback? onClearSelection,
  }) {
    return ReaderSelectionState(
      text: text ?? this.text,
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      onSelectAll: onSelectAll ?? this.onSelectAll,
      onHideToolbar: onHideToolbar ?? this.onHideToolbar,
      onClearSelection: onClearSelection ?? this.onClearSelection,
    );
  }
}

/// Provider for managing reader text selection and floating card visibility without modal barriers.
final readerSelectionControllerProvider =
    NotifierProvider<ReaderSelectionController, ReaderSelectionState>(
  ReaderSelectionController.new,
);

class ReaderSelectionController extends Notifier<ReaderSelectionState> {
  @override
  ReaderSelectionState build() => const ReaderSelectionState();

  /// Shows the floating bottom card in Small Peeking state (~175dp).
  void showPeeking({
    required String text,
    VoidCallback? onSelectAll,
    VoidCallback? onHideToolbar,
    VoidCallback? onClearSelection,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) {
      dismiss();
      return;
    }
    state = ReaderSelectionState(
      text: clean,
      isVisible: true,
      isExpanded: false,
      isFullScreen: false,
      onSelectAll: onSelectAll ?? state.onSelectAll,
      onHideToolbar: onHideToolbar ?? state.onHideToolbar,
      onClearSelection: onClearSelection ?? state.onClearSelection,
    );
  }

  /// Shows or expands the card into Big Card mode (70% height).
  void showExpanded({
    required String text,
    VoidCallback? onSelectAll,
    VoidCallback? onHideToolbar,
    VoidCallback? onClearSelection,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) {
      dismiss();
      return;
    }
    state = ReaderSelectionState(
      text: clean,
      isVisible: true,
      isExpanded: true,
      isFullScreen: false,
      onSelectAll: onSelectAll ?? state.onSelectAll,
      onHideToolbar: onHideToolbar ?? state.onHideToolbar,
      onClearSelection: onClearSelection ?? state.onClearSelection,
    );
  }

  /// Expands current peeking card into Big Card mode.
  void expand() {
    if (state.isVisible && !state.isExpanded) {
      state = state.copyWith(isExpanded: true, isFullScreen: false);
    }
  }

  /// Toggles between Full Screen mode and standard Big Card (70%) mode.
  void toggleFullScreen() {
    if (state.isVisible) {
      final nextFullScreen = !state.isFullScreen;
      state = state.copyWith(
        isFullScreen: nextFullScreen,
        isExpanded: true,
      );
    }
  }

  /// Collapses Big Card back to Small Peeking card mode.
  void collapse() {
    if (state.isVisible && state.isExpanded) {
      state = state.copyWith(isExpanded: false, isFullScreen: false);
    }
  }

  /// Registers an active hideToolbar callback from Flutter's SelectableRegionState.
  void registerHideToolbarCallback(VoidCallback callback) {
    if (state.onHideToolbar != callback) {
      state = state.copyWith(onHideToolbar: callback);
    }
  }

  /// Registers an active clearSelection callback from the reader surface.
  void registerClearSelectionCallback(VoidCallback callback) {
    if (state.onClearSelection != callback) {
      state = state.copyWith(onClearSelection: callback);
    }
  }

  /// Completely dismisses the floating card and deselects the text without blocking any touches.
  void dismiss() {
    if (state.isVisible || state.text.isNotEmpty) {
      final clearCallback = state.onClearSelection;
      final hideCallback = state.onHideToolbar;
      state = const ReaderSelectionState();
      hideCallback?.call();
      clearCallback?.call();
    }
  }
}
