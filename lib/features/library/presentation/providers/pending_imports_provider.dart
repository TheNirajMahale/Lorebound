import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class PendingImport {
  final String id;
  final String fileName;

  const PendingImport(this.id, this.fileName);
}

class PendingImportsNotifier extends Notifier<List<PendingImport>> {
  @override
  List<PendingImport> build() => [];

  void addFiles(List<PlatformFile> files) {
    state = [
      ...state,
      ...files.map((f) => PendingImport(f.path ?? f.name, f.name))
    ];
  }

  void removeFile(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final pendingImportsProvider =
    NotifierProvider<PendingImportsNotifier, List<PendingImport>>(() {
  return PendingImportsNotifier();
});
