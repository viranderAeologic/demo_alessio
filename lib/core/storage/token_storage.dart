import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Persists the authentication token on the device.
///
/// Kept behind an interface so the repositories can be unit tested with an
/// in-memory implementation.
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clearToken();
}

/// [TokenStorage] backed by the platform secure storage
/// (Keychain on iOS, Keystore-encrypted preferences on Android).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              // Token is available after the first unlock and never leaves
              // the device (not included in iCloud/iTunes backups).
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: StorageKeys.accessToken);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: StorageKeys.accessToken);
}
