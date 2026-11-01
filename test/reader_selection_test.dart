import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/reader/presentation/providers/reader_selection_controller.dart';

void main() {
  group('Reader Selection Controller Tests', () {
    test('Initial state is hidden with empty text', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(readerSelectionControllerProvider);
      expect(state.isVisible, isFalse);
      expect(state.isExpanded, isFalse);
      expect(state.text, isEmpty);
    });

    test('showPeeking sets state to visible and collapsed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.showPeeking(text: 'ephemeral');

      final state = container.read(readerSelectionControllerProvider);
      expect(state.isVisible, isTrue);
      expect(state.isExpanded, isFalse);
      expect(state.text, 'ephemeral');
    });

    test('showExpanded sets state to visible and expanded', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.showExpanded(text: 'in cold blood');

      final state = container.read(readerSelectionControllerProvider);
      expect(state.isVisible, isTrue);
      expect(state.isExpanded, isTrue);
      expect(state.text, 'in cold blood');
    });

    test('expand and collapse transitions function correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.showPeeking(text: 'serendipity');

      expect(container.read(readerSelectionControllerProvider).isExpanded, isFalse);

      notifier.expand();
      expect(container.read(readerSelectionControllerProvider).isExpanded, isTrue);

      notifier.collapse();
      expect(container.read(readerSelectionControllerProvider).isExpanded, isFalse);

      notifier.dismiss();
      expect(container.read(readerSelectionControllerProvider).isVisible, isFalse);
      expect(container.read(readerSelectionControllerProvider).text, isEmpty);
    });

    test('Empty text dismisses selection automatically', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.showPeeking(text: '   ');

      final state = container.read(readerSelectionControllerProvider);
      expect(state.isVisible, isFalse);
    });

    test('toggleFullScreen transitions between full screen and expanded correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.showExpanded(text: 'luminescence');

      expect(container.read(readerSelectionControllerProvider).isExpanded, isTrue);
      expect(container.read(readerSelectionControllerProvider).isFullScreen, isFalse);

      notifier.toggleFullScreen();
      expect(container.read(readerSelectionControllerProvider).isFullScreen, isTrue);
      expect(container.read(readerSelectionControllerProvider).isExpanded, isTrue);

      notifier.toggleFullScreen();
      expect(container.read(readerSelectionControllerProvider).isFullScreen, isFalse);
      expect(container.read(readerSelectionControllerProvider).isExpanded, isTrue);

      notifier.collapse();
      expect(container.read(readerSelectionControllerProvider).isFullScreen, isFalse);
      expect(container.read(readerSelectionControllerProvider).isExpanded, isFalse);
    });

    test('dismiss triggers onClearSelection callback to deselect text in reader', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      bool cleared = false;
      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.showPeeking(
        text: 'wanderlust',
        onClearSelection: () {
          cleared = true;
        },
      );

      expect(container.read(readerSelectionControllerProvider).isVisible, isTrue);
      expect(cleared, isFalse);

      notifier.dismiss();
      expect(container.read(readerSelectionControllerProvider).isVisible, isFalse);
      expect(cleared, isTrue);
    });

    test('showPeeking preserves registered onHideToolbar callback and triggers on dismiss', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      bool toolbarHidden = false;
      final notifier = container.read(readerSelectionControllerProvider.notifier);
      notifier.registerHideToolbarCallback(() {
        toolbarHidden = true;
      });

      notifier.showPeeking(text: 'petrichor');
      expect(container.read(readerSelectionControllerProvider).isVisible, isTrue);
      expect(container.read(readerSelectionControllerProvider).onHideToolbar, isNotNull);

      // Expand does not destroy the toolbar overlay entry
      notifier.expand();
      expect(container.read(readerSelectionControllerProvider).isExpanded, isTrue);
      expect(toolbarHidden, isFalse);

      // Dismiss properly cleans up the toolbar overlay
      notifier.dismiss();
      expect(container.read(readerSelectionControllerProvider).isVisible, isFalse);
      expect(toolbarHidden, isTrue);
    });
  });
}
