import 'package:flutter_test/flutter_test.dart';
import 'package:product_browser/core/errors/app_exception.dart';
import 'package:product_browser/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:product_browser/features/auth/domain/models/auth_session.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryTokenStorage storage;
  late FakeAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  setUp(() {
    storage = InMemoryTokenStorage();
    remote = FakeAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remote: remote, tokenStorage: storage);
  });

  group('login', () {
    test('persists the token on success', () async {
      remote.onLogin = (u, p) async =>
          const AuthSession(accessToken: 'tok', user: testUser);

      final session = await repository.login(username: 'emilys', password: 'x');

      expect(session.accessToken, 'tok');
      expect(session.user, same(testUser));
      expect(storage.token, 'tok');
    });

    test('does not persist anything when login fails', () async {
      remote.onLogin = (u, p) async => throw const UnauthorizedException();

      await expectLater(
        repository.login(username: 'emilys', password: 'bad'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(storage.token, isNull);
    });
  });

  group('restoreSession', () {
    test('returns null when no token is stored', () async {
      expect(await repository.restoreSession(), isNull);
    });

    test('returns the session with user when the token is valid', () async {
      storage.token = 'tok';
      remote.onCurrentUser = () async => testUser;

      final session = await repository.restoreSession();

      expect(session?.accessToken, 'tok');
      expect(session?.user, same(testUser));
    });

    test('clears the token and returns null when it was rejected', () async {
      storage.token = 'expired';
      remote.onCurrentUser = () async => throw const UnauthorizedException();

      expect(await repository.restoreSession(), isNull);
      expect(storage.token, isNull);
    });

    test('keeps the session (without user) when offline', () async {
      storage.token = 'tok';
      remote.onCurrentUser = () async => throw const NetworkException();

      final session = await repository.restoreSession();

      expect(session?.accessToken, 'tok');
      expect(session?.user, isNull);
      expect(storage.token, 'tok');
    });
  });

  test('logout clears the token', () async {
    storage.token = 'tok';

    await repository.logout();

    expect(storage.token, isNull);
  });
}
