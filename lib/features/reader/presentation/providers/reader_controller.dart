import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reader_config.dart';

class ReaderState {
  final ReaderConfig config;
  final String? bookPath;
  final bool isAsset;

  const ReaderState({
    required this.config,
    this.bookPath,
    this.isAsset = false,
  });

  ReaderState copyWith({
    ReaderConfig? config,
    String? bookPath,
    bool? isAsset,
  }) {
    return ReaderState(
      config: config ?? this.config,
      bookPath: bookPath ?? this.bookPath,
      isAsset: isAsset ?? this.isAsset,
    );
  }
}

class ReaderController extends Notifier<ReaderState> {
  @override
  ReaderState build() {
    return const ReaderState(config: ReaderConfig());
  }

  void updateConfig(ReaderConfig newConfig) {
    state = state.copyWith(config: newConfig);
  }

  void loadBookFromAsset(String assetPath) {
    state = state.copyWith(bookPath: assetPath, isAsset: true);
  }

  void loadBookFromFile(String filePath) {
    state = state.copyWith(bookPath: filePath, isAsset: false);
  }
}

final readerControllerProvider = NotifierProvider<ReaderController, ReaderState>(() {
  return ReaderController();
});
