/// Base type for all errors surfaced to the presentation layer.
///
/// Every exception carries a user-facing [message] so controllers can expose
/// it directly without needing to know the underlying cause.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The device could not reach the server (offline, DNS failure, timeout).
final class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Unable to reach the server. Check your connection and try again.',
  ]);
}

/// The server answered with a non-2xx status code.
final class ServerException extends AppException {
  const ServerException(this.statusCode, super.message);

  final int statusCode;
}

/// Credentials were rejected or the session is no longer valid (401/403).
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Invalid username or password.',
  ]);
}

/// The response body was not in the expected shape.
final class ParseException extends AppException {
  const ParseException([
    super.message = 'Received an unexpected response from the server.',
  ]);
}

/// Catch-all for anything not covered above.
final class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
