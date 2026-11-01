import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_exceptions.dart';
import 'auth_interceptor.dart';
import 'secure_storage_service.dart';

/// Provider for the centralized ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final authInterceptor = ref.watch(authInterceptorProvider);
  return ApiClient(secureStorage, authInterceptor);
});

/// Centralized HTTP client managing Dio configurations, request wrapping,
/// and Spring Boot error normalization.
class ApiClient {
  final SecureStorageService _storage;
  final AuthInterceptor _authInterceptor;
  late final Dio _dio;
  bool _isInitialized = false;

  ApiClient(this._storage, this._authInterceptor) {
    _dio = Dio(
      BaseOptions(
        baseUrl: SecureStorageService.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_authInterceptor);
  }

  /// Ensures the client has loaded the latest user-configured base URL.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      final baseUrl = await _storage.getBaseUrl();
      _dio.options.baseUrl = baseUrl;
      _isInitialized = true;
    }
  }

  /// Updates the base URL dynamically when changed in user settings.
  void updateBaseUrl(String newBaseUrl) {
    var trimmed = newBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _dio.options.baseUrl = trimmed;
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _ensureInitialized();
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    await _ensureInitialized();
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInitialized();
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInitialized();
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Streaming file download
  Future<Response> download(
    String path,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    await _ensureInitialized();
    try {
      return await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
