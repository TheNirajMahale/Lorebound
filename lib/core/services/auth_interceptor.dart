import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

/// Provider for the AuthInterceptor.
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthInterceptor(secureStorage);
});

/// Interceptor that attaches the JWT Bearer token to authenticated requests
/// and handles 401 Unauthorized token expirations.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  void Function()? onSessionExpired;

  AuthInterceptor(this._storage, {this.onSessionExpired});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add User-Agent and standard headers
    options.headers['User-Agent'] = 'Lorebound/1.0.0 (Flutter)';
    if (!options.headers.containsKey('Accept')) {
      options.headers['Accept'] = 'application/json';
    }

    // Skip attaching token for unauthenticated endpoints
    final path = options.path;
    final isAuthEndpoint = path.startsWith('/auth/') || 
                           path.startsWith('/open-library/') ||
                           path == '/highlight';

    if (!isAuthEndpoint) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final isAuthEndpoint = err.requestOptions.path.startsWith('/auth/');

    if (statusCode == 401 && !isAuthEndpoint) {
      // Token is stale or invalid
      onSessionExpired?.call();
    }

    return handler.next(err);
  }
}
