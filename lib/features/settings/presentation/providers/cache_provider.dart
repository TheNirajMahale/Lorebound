import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class CacheController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return _calculateCacheSize();
  }

  Future<String> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> entities = tempDir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        }
      }
      
      return _formatSize(totalSize);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> clearCache() async {
    state = const AsyncValue.loading();
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> entities = tempDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {
            // Ignore files that can't be deleted
          }
        }
      }
      // Refresh the cache size
      state = await AsyncValue.guard(() => _calculateCacheSize());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final cacheControllerProvider = AsyncNotifierProvider<CacheController, String>(() {
  return CacheController();
});
