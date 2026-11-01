import '../../../../core/database/app_database.dart';
import 'book.dart';

/// The tri-state storage lifecycle of a book in Lorebound.
///
/// Derived with zero schema migration risk from existing nullable fields:
/// - [localOnly]: Stored purely on device without cloud link (`backendId == null`).
/// - [cloudOnly]: Catalog record in LoreKeeper, not downloaded (`backendId != null && filePath == null`).
/// - [synced]: Linked to LoreKeeper AND downloaded locally (`backendId != null && filePath != null`).
enum BookStorageState {
  localOnly,
  cloudOnly,
  synced,
}

extension BookStorageStateX on Book {
  BookStorageState get storageState {
    if (backendId == null) {
      return BookStorageState.localOnly;
    }
    if (filePath == null || filePath!.isEmpty) {
      return BookStorageState.cloudOnly;
    }
    return BookStorageState.synced;
  }

  bool get isLocalOnly => storageState == BookStorageState.localOnly;
  bool get isCloudOnly => storageState == BookStorageState.cloudOnly;
  bool get isSynced => storageState == BookStorageState.synced;
  bool get isDownloaded => filePath != null && filePath!.isNotEmpty;
}

extension BookEntityStorageStateX on BookEntity {
  BookStorageState get storageState {
    if (backendId == null) {
      return BookStorageState.localOnly;
    }
    if (filePath == null || filePath!.isEmpty) {
      return BookStorageState.cloudOnly;
    }
    return BookStorageState.synced;
  }

  bool get isLocalOnly => storageState == BookStorageState.localOnly;
  bool get isCloudOnly => storageState == BookStorageState.cloudOnly;
  bool get isSynced => storageState == BookStorageState.synced;
  bool get isDownloaded => filePath != null && filePath!.isNotEmpty;
}
