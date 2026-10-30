import 'auth_user.dart';

/// An authenticated session: the access token plus (when known) the user.
///
/// [user] is `null` when the session was restored from storage but the user
/// profile could not be fetched (for example, the device is offline).
class AuthSession {
  const AuthSession({required this.accessToken, this.user});

  final String accessToken;
  final AuthUser? user;
}
