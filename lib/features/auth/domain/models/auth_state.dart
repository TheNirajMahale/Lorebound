import 'user.dart';

/// Enum representing the high-level authentication status.
enum AuthStatus {
  guest,
  authenticated,
  loading,
  error,
}

/// Immutable state container for the user session.
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isGuest => status == AuthStatus.guest;
  bool get isLoading => status == AuthStatus.loading;

  factory AuthState.guest() {
    return const AuthState(status: AuthStatus.guest);
  }

  factory AuthState.authenticated({required User user, required String token}) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: token,
    );
  }

  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}
