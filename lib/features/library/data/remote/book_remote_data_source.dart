import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';

/// Provider for BookRemoteDataSource.
final bookRemoteDataSourceProvider = Provider<BookRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookRemoteDataSource(apiClient);
});

/// Remote data source handling communication with LoreKeeper `/books` endpoints.
class BookRemoteDataSource {
  final ApiClient _apiClient;

  BookRemoteDataSource(this._apiClient);

  /// Retrieves all books for the authenticated user from LoreKeeper.
  Future<List<Map<String, dynamic>>> getUserBooks({
    String? status,
    String? query,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (query != null && query.isNotEmpty) queryParams['query'] = query;

    final response = await _apiClient.get<List<dynamic>>(
      '/books',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) return [];
    return response.data!.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  /// Retrieves a single book by its LoreKeeper backend ID.
  Future<Map<String, dynamic>> getBook(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/books/$id');
    return response.data ?? {};
  }

  /// Creates a book record on LoreKeeper.
  Future<Map<String, dynamic>> createBook(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/books',
      data: data,
    );
    return response.data ?? {};
  }

  /// Updates an existing book record on LoreKeeper.
  Future<Map<String, dynamic>> updateBook(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/books/$id',
      data: data,
    );
    return response.data ?? {};
  }

  /// Deletes a book record from LoreKeeper.
  Future<void> deleteBook(int id) async {
    await _apiClient.delete<void>('/books/$id');
  }
}
