import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';

/// Talks to the DummyJSON auth endpoints.
abstract class AuthRemoteDataSource {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  /// Fetches the profile of the user owning the stored token (`/auth/me`).
  Future<AuthUser> currentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final json = await _client.post(
      ApiConstants.loginPath,
      body: {'username': username, 'password': password},
    );

    final token = json['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const ParseException('Login response did not include a token.');
    }

    return AuthSession(accessToken: token, user: AuthUser.fromJson(json));
  }

  @override
  Future<AuthUser> currentUser() async {
    final json = await _client.get(ApiConstants.currentUserPath);
    return AuthUser.fromJson(json);
  }
}
