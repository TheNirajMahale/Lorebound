import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for accessing the secure storage service.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  return SecureStorageService(storage);
});

/// Service responsible for securely persisting tokens, server configs, and cached user credentials.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyJwtToken = 'lorekeeper_jwt_token';
  static const String _keyBaseUrl = 'lorekeeper_base_url';
  static const String _keyUserProfile = 'lorekeeper_user_profile';
  static const String defaultBaseUrl = 'http://localhost:8080';

  SecureStorageService(this._storage);

  /// Retrieves the persisted JWT token, or null if unauthenticated.
  Future<String?> getToken() async {
    return _storage.read(key: _keyJwtToken);
  }

  /// Persists the active JWT token.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  /// Removes the stored JWT token.
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyJwtToken);
  }

  /// Retrieves the user-configured server base URL or falls back to [defaultBaseUrl].
  Future<String> getBaseUrl() async {
    final storedUrl = await _storage.read(key: _keyBaseUrl);
    if (storedUrl != null && storedUrl.trim().isNotEmpty) {
      return storedUrl.trim();
    }
    return defaultBaseUrl;
  }

  /// Persists a custom server base URL.
  Future<void> saveBaseUrl(String url) async {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    await _storage.write(key: _keyBaseUrl, value: trimmed);
  }

  /// Retrieves the cached user profile as a Map.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = await _storage.read(key: _keyUserProfile);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Caches the current authenticated user's profile.
  Future<void> saveUserProfile(Map<String, dynamic> userProfile) async {
    await _storage.write(key: _keyUserProfile, value: jsonEncode(userProfile));
  }

  /// Deletes the cached user profile.
  Future<void> deleteUserProfile() async {
    await _storage.delete(key: _keyUserProfile);
  }

  /// Wipes all credentials and cached session data (used during logout).
  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyJwtToken);
    await _storage.delete(key: _keyUserProfile);
  }
}

