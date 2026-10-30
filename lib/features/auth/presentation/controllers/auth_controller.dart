import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// App-wide session state: who is signed in, and login/logout actions.
///
/// Registered once (permanent) by the initial binding so route middlewares
/// and other features can read [isAuthenticated] at any time.
class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final RxBool isAuthenticated = false.obs;
  final Rxn<AuthUser> user = Rxn<AuthUser>();

  final RxBool isLoggingIn = false.obs;
  final RxnString loginError = RxnString();

  /// Reads the persisted token and, when possible, the user profile.
  /// Called once at startup before the first route is decided.
  Future<void> restoreSession() async {
    try {
      _applySession(await _repository.restoreSession());
    } catch (_) {
      _applySession(null);
    }
  }

  /// Returns `true` when login succeeded. Ignores calls while a login is
  /// already in flight so double taps cannot fire duplicate requests.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (isLoggingIn.value) return false;

    isLoggingIn.value = true;
    loginError.value = null;
    try {
      final session = await _repository.login(
        username: username.trim(),
        password: password,
      );
      _applySession(session);
      Get.offAllNamed(AppRoutes.products);
      return true;
    } on AppException catch (e) {
      loginError.value = e.message;
      return false;
    } catch (_) {
      loginError.value = const UnknownException().message;
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _applySession(null);
    Get.offAllNamed(AppRoutes.login);
  }

  void clearLoginError() => loginError.value = null;

  void _applySession(AuthSession? session) {
    isAuthenticated.value = session != null;
    user.value = session?.user;
  }
}
