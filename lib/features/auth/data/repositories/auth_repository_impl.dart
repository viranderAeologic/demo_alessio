import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remote, required this._tokenStorage});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final session = await _remote.login(username: username, password: password);
    await _tokenStorage.writeToken(session.accessToken);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _remote.currentUser();
      return AuthSession(accessToken: token, user: user);
    } on UnauthorizedException {
      // Token expired or was revoked: drop it so the user signs in again.
      await _tokenStorage.clearToken();
      return null;
    } on AppException {
      // Offline or server error: keep the session, user profile unknown.
      return AuthSession(accessToken: token);
    }
  }

  @override
  Future<void> logout() => _tokenStorage.clearToken();
}
