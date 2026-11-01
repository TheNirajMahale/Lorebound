import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/api_exceptions.dart';
import '../../../../core/services/auth_interceptor.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/remote/auth_remote_data_source.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/user.dart';

/// Provider for the global SessionController.
final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, AuthState>(SessionController.new);

/// Controller managing the user's authentication lifecycle and session state.
class SessionController extends AsyncNotifier<AuthState> {
  late final SecureStorageService _storage;
  late final AuthRemoteDataSource _authRemoteDataSource;
  late final ApiClient _apiClient;
  late final AuthInterceptor _authInterceptor;

  @override
  Future<AuthState> build() async {
    _storage = ref.watch(secureStorageServiceProvider);
    _authRemoteDataSource = ref.watch(authRemoteDataSourceProvider);
    _apiClient = ref.watch(apiClientProvider);
    _authInterceptor = ref.watch(authInterceptorProvider);

    // Register session expiration callback to reset to guest if token is rejected
    _authInterceptor.onSessionExpired = () {
      logout();
    };

    return _restoreSession();
  }

  /// Attempts to restore a previous session from encrypted secure storage.
  Future<AuthState> _restoreSession() async {
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        return AuthState.guest();
      }

      // Try reading cached user profile first for instant startup
      final cachedProfile = await _storage.getUserProfile();
      User? user;
      if (cachedProfile != null) {
        user = User.fromJson(cachedProfile);
      }

      // In the background or fallback, verify with server
      try {
        final freshUser = await _authRemoteDataSource.getCurrentUser();
        await _storage.saveUserProfile(freshUser.toJson());
        return AuthState.authenticated(user: freshUser, token: token);
      } catch (e) {
        // If server is unreachable offline, but we have cached profile, keep offline authenticated state
        if (user != null) {
          return AuthState.authenticated(user: user, token: token);
        }
        // If 401 or invalid, reset to guest
        if (e is ApiException && e.statusCode == 401) {
          await _storage.clearAuthData();
          return AuthState.guest();
        }
        // Otherwise start as guest
        return AuthState.guest();
      }
    } catch (_) {
      return AuthState.guest();
    }
  }

  /// Registers a new account and immediately authenticates.
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authToken = await _authRemoteDataSource.register(
        email: email,
        password: password,
      );

      await _storage.saveToken(authToken.token);
      await _storage.saveUserProfile(authToken.user.toJson());

      state = AsyncValue.data(
        AuthState.authenticated(
          user: authToken.user,
          token: authToken.token,
        ),
      );
      return true;
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState.error(e.message));
      return false;
    } catch (e) {
      state = AsyncValue.data(AuthState.error(e.toString()));
      return false;
    }
  }

  /// Logs into an existing account.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authToken = await _authRemoteDataSource.login(
        email: email,
        password: password,
      );

      await _storage.saveToken(authToken.token);
      await _storage.saveUserProfile(authToken.user.toJson());

      state = AsyncValue.data(
        AuthState.authenticated(
          user: authToken.user,
          token: authToken.token,
        ),
      );
      return true;
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState.error(e.message));
      return false;
    } catch (e) {
      state = AsyncValue.data(AuthState.error(e.toString()));
      return false;
    }
  }

  /// Logs in via Google OAuth idToken.
  Future<bool> loginWithGoogle(String idToken) async {
    state = const AsyncValue.loading();
    try {
      final authToken = await _authRemoteDataSource.loginWithGoogle(
        idToken: idToken,
      );

      await _storage.saveToken(authToken.token);
      await _storage.saveUserProfile(authToken.user.toJson());

      state = AsyncValue.data(
        AuthState.authenticated(
          user: authToken.user,
          token: authToken.token,
        ),
      );
      return true;
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState.error(e.message));
      return false;
    } catch (e) {
      state = AsyncValue.data(AuthState.error(e.toString()));
      return false;
    }
  }

  /// Requests a password reset token for the given email.
  Future<String?> forgotPassword(String email) async {
    try {
      final res = await _authRemoteDataSource.forgotPassword(email);
      return res['resetToken'] as String?;
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState.error(e.message));
      return null;
    } catch (e) {
      state = AsyncValue.data(AuthState.error(e.toString()));
      return null;
    }
  }

  /// Resets user password using the token.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authRemoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState.error(e.message));
      return false;
    } catch (e) {
      state = AsyncValue.data(AuthState.error(e.toString()));
      return false;
    }
  }

  /// Updates and persists custom server base URL.
  Future<void> updateServerUrl(String url) async {
    await _storage.saveBaseUrl(url);
    _apiClient.updateBaseUrl(url);
  }

  /// Retrieves the active server base URL.
  Future<String> getServerUrl() async {
    return _storage.getBaseUrl();
  }

  /// Logs out the user and clears all credentials.
  Future<void> logout() async {
    await _storage.clearAuthData();
    state = AsyncValue.data(AuthState.guest());
  }
}
