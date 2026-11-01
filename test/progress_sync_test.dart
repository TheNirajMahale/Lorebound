import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/library/data/services/progress_sync_service.dart';

void main() {
  group('Durable Progress Sync Tests', () {
    test('ProgressSyncService constant key matches specification', () {
      expect(ProgressSyncService.dirtyQueueKey, 'pending_sync_book_ids');
    });
  });
}
