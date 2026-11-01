import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/models/auth_token.dart';
import '../../domain/models/user.dart';

/// Provider for accessing the AuthRemoteDataSource.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient);
});

/// Data source handling communication with Lorekeeper authentication endpoints.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// Registers a new user with email and password.
  Future<AuthToken> register({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    return AuthToken.fromJson(response.data!);
  }

  /// Logs in an existing user with email and password.
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    return AuthToken.fromJson(response.data!);
  }

  /// Completes Google OAuth login using an idToken.
  Future<AuthToken> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/google',
      data: {
        'idToken': idToken,
      },
    );

    return AuthToken.fromJson(response.data!);
  }

  /// Retrieves the current authenticated user's profile.
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/me');
    return User.fromJson(response.data!);
  }

  /// Requests a password reset token for the given email.
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email.trim()},
    );
    return response.data ?? {};
  }

  /// Resets password using the received token and new password.
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {
        'token': token.trim(),
        'newPassword': newPassword,
      },
    );
    return response.data ?? {};
  }
}
