import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_browser/core/errors/app_exception.dart';
import 'package:product_browser/features/auth/domain/models/auth_session.dart';
import 'package:product_browser/features/auth/presentation/controllers/auth_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUpAll(() {
    // Contextless navigation reads the navigator key, which requires a binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
  });

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository);
  });

  group('restoreSession', () {
    test('marks the user authenticated when a session exists', () async {
      repository.onRestore = () async =>
          const AuthSession(accessToken: 'tok', user: testUser);

      await controller.restoreSession();

      expect(controller.isAuthenticated.value, isTrue);
      expect(controller.user.value, same(testUser));
    });

    test('stays unauthenticated when nothing is stored', () async {
      await controller.restoreSession();

      expect(controller.isAuthenticated.value, isFalse);
      expect(controller.user.value, isNull);
    });

    test('swallows unexpected errors and stays unauthenticated', () async {
      repository.onRestore = () async => throw StateError('boom');

      await controller.restoreSession();

      expect(controller.isAuthenticated.value, isFalse);
    });
  });

  group('login', () {
    test('toggles the in-progress flag and authenticates on success', () async {
      final gate = Completer<AuthSession>();
      repository.onLogin = (u, p) => gate.future;

      final future = controller.login(username: ' emilys ', password: 'pw');
      expect(controller.isLoggingIn.value, isTrue);

      gate.complete(const AuthSession(accessToken: 'tok', user: testUser));
      expect(await future, isTrue);

      expect(controller.isLoggingIn.value, isFalse);
      expect(controller.isAuthenticated.value, isTrue);
      expect(controller.loginError.value, isNull);
    });

    test('trims the username before sending it', () async {
      String? sent;
      repository.onLogin = (u, p) async {
        sent = u;
        return const AuthSession(accessToken: 'tok');
      };

      await controller.login(username: '  emilys ', password: 'pw');

      expect(sent, 'emilys');
    });

    test('exposes the error message on failure', () async {
      repository.onLogin = (u, p) async =>
          throw const UnauthorizedException('Invalid credentials');

      expect(await controller.login(username: 'a', password: 'b'), isFalse);

      expect(controller.loginError.value, 'Invalid credentials');
      expect(controller.isAuthenticated.value, isFalse);
      expect(controller.isLoggingIn.value, isFalse);
    });

    test('ignores a second submission while one is in flight', () async {
      var calls = 0;
      final gate = Completer<AuthSession>();
      repository.onLogin = (u, p) {
        calls++;
        return gate.future;
      };

      final first = controller.login(username: 'a', password: 'b');
      final second = await controller.login(username: 'a', password: 'b');

      expect(second, isFalse);
      gate.complete(const AuthSession(accessToken: 'tok'));
      await first;
      expect(calls, 1);
    });
  });

  test('logout clears the session', () async {
    repository.onRestore = () async =>
        const AuthSession(accessToken: 'tok', user: testUser);
    await controller.restoreSession();

    await controller.logout();

    expect(repository.logoutCalls, 1);
    expect(controller.isAuthenticated.value, isFalse);
    expect(controller.user.value, isNull);
  });
}
