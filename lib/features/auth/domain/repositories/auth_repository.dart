import '../models/auth_session.dart';

/// Contract used by the presentation layer for everything auth related.
abstract class AuthRepository {
  /// Authenticates with the backend and persists the returned access token.
  ///
  /// Throws an [AppException] subtype on failure.
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  /// Restores a previously persisted session.
  ///
  /// Returns `null` when no token is stored or the stored token has been
  /// rejected by the server (in which case it is also cleared).
  Future<AuthSession?> restoreSession();

  /// Clears the persisted token.
  Future<void> logout();
}
