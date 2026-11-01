import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/auth/domain/models/user.dart';
import 'package:lorebound/features/auth/domain/models/auth_token.dart';
import 'package:lorebound/features/auth/domain/models/auth_state.dart';

void main() {
  group('Auth Domain Models Tests', () {
    test('User fromJson and toJson serialization', () {
      final json = {
        'id': 42,
        'email': 'reader@example.com',
        'authProvider': 'LOCAL',
        'createdAt': '2026-10-13T12:00:00.000',
      };

      final user = User.fromJson(json);
      expect(user.id, 42);
      expect(user.email, 'reader@example.com');
      expect(user.authProvider, 'LOCAL');
      expect(user.createdAt, isNotNull);

      final output = user.toJson();
      expect(output['id'], 42);
      expect(output['email'], 'reader@example.com');
      expect(output['authProvider'], 'LOCAL');
    });

    test('AuthToken fromJson parses nested user', () {
      final json = {
        'token': 'jwt_mock_token_abc',
        'user': {
          'id': 1,
          'email': 'test@lorekeeper.com',
          'authProvider': 'LOCAL',
        },
      };

      final authToken = AuthToken.fromJson(json);
      expect(authToken.token, 'jwt_mock_token_abc');
      expect(authToken.user.id, 1);
      expect(authToken.user.email, 'test@lorekeeper.com');
    });

    test('AuthState state transitions and helper flags', () {
      final guest = AuthState.guest();
      expect(guest.isGuest, isTrue);
      expect(guest.isAuthenticated, isFalse);
      expect(guest.isLoading, isFalse);

      final loading = AuthState.loading();
      expect(loading.isLoading, isTrue);
      expect(loading.isAuthenticated, isFalse);

      const user = User(id: 1, email: 'user@test.com', authProvider: 'LOCAL');
      final authenticated = AuthState.authenticated(user: user, token: 'token123');
      expect(authenticated.isAuthenticated, isTrue);
      expect(authenticated.isGuest, isFalse);
      expect(authenticated.user?.email, 'user@test.com');
      expect(authenticated.token, 'token123');

      final error = AuthState.error('Network failed');
      expect(error.errorMessage, 'Network failed');
      expect(error.isAuthenticated, isFalse);
    });
  });
}
