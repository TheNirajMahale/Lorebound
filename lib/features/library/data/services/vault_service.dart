import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/models/book.dart';
import '../remote/book_remote_data_source.dart';
import '../repositories/local_book_repository.dart';

/// Provider for VaultService.
final vaultServiceProvider = Provider<VaultService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localRepo = ref.watch(localBookRepositoryProvider);
  final bookRemoteDataSource = ref.watch(bookRemoteDataSourceProvider);
  return VaultService(
    apiClient: apiClient,
    localRepo: localRepo,
    bookRemoteDataSource: bookRemoteDataSource,
  );
});

/// Service handling document transfers (Vault upload & download) between Lorebound and LoreKeeper.
class VaultService {
  final ApiClient apiClient;
  final LocalBookRepository localRepo;
  final BookRemoteDataSource bookRemoteDataSource;

  VaultService({
    required this.apiClient,
    required this.localRepo,
    required this.bookRemoteDataSource,
  });

  /// Uploads a local EPUB file to LoreKeeper Vault and links the catalog record.
  ///
  /// Transitions book from `localOnly` to `synced`.
  Future<bool> uploadBook(
    Book book, {
    void Function(int sent, int total)? onProgress,
  }) async {
    if (book.filePath == null || !File(book.filePath!).existsSync()) {
      return false;
    }

    try {
      final file = File(book.filePath!);
      final fileName = book.filePath!.split(Platform.pathSeparator).last;
      final cleanFileName = fileName.toLowerCase().endsWith('.epub') ? fileName : '${book.title}.epub';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: cleanFileName,
          contentType: DioMediaType('application', 'epub+zip'),
        ),
      });

      // 1. Upload file to /documents/import
      final importResponse = await apiClient.post<Map<String, dynamic>>(
        '/documents/import',
        data: formData,
        onSendProgress: onProgress,
      );

      final documentId = importResponse.data?['documentId']?.toString();
      if (documentId == null) return false;

      // 2. Create or link book record on LoreKeeper
      final bookPayload = {
        'title': book.title,
        'author': book.author ?? 'Unknown Author',
        'summary': book.summary,
        'format': book.format,
        'status': book.status,
        'currentChapter': book.currentChapter,
        'currentPage': book.currentPage,
        'readingPosition': book.readingPosition,
        'totalPages': book.totalPages,
        'totalChapters': book.totalChapters > 0 ? book.totalChapters : (importResponse.data?['chapters'] as List?)?.length ?? 0,
        'rating': book.rating,
        'isFavorite': book.isFavorite,
        'openLibraryWorkId': book.openLibraryWorkId,
        'openLibraryEditionId': book.openLibraryEditionId,
        'documentId': documentId,
      };

      int backendId;
      if (book.backendId != null) {
        final updated = await bookRemoteDataSource.updateBook(book.backendId!, bookPayload);
        backendId = (updated['id'] as num).toInt();
      } else {
        final created = await bookRemoteDataSource.createBook(bookPayload);
        backendId = (created['id'] as num).toInt();
      }

      // 3. Update local SQLite record
      final existingEntity = await localRepo.getBookById(book.id);
      if (existingEntity != null) {
        await localRepo.updateBook(
          existingEntity.copyWith(
            backendId: Value(backendId),
            documentId: Value(documentId),
          ),
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Downloads an EPUB document from LoreKeeper Vault to local storage.
  ///
  /// Transitions book from `cloudOnly` to `synced`.
  Future<bool> downloadBook(
    Book book, {
    void Function(int received, int total)? onProgress,
  }) async {
    String? docId = book.documentId;

    // If documentId is not yet cached locally, query remote book
    if (docId == null && book.backendId != null) {
      try {
        final remoteBook = await bookRemoteDataSource.getBook(book.backendId!);
        docId = remoteBook['documentId']?.toString();
      } catch (_) {
        return false;
      }
    }

    if (docId == null || docId.isEmpty) return false;

    try {
      final response = await apiClient.get<List<int>>(
        '/documents/$docId/download',
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );

      if (response.data == null || response.data!.isEmpty) return false;

      // Save file locally to app storage
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final sanitizedTitle = book.title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final targetPath = '${booksDir.path}/${book.id}_$sanitizedTitle.epub';
      final file = File(targetPath);
      await file.writeAsBytes(response.data!);

      // Update local Drift SQLite record
      final existingEntity = await localRepo.getBookById(book.id);
      if (existingEntity != null) {
        await localRepo.updateBook(
          existingEntity.copyWith(
            filePath: Value(targetPath),
            documentId: Value(docId),
          ),
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
