import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';

/// Form state for the login screen. Scoped to the login route so the text
/// controllers are disposed when the screen is left.
class LoginController extends GetxController {
  LoginController(this._auth);

  final AuthController _auth;

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool obscurePassword = true.obs;

  RxBool get isSubmitting => _auth.isLoggingIn;
  RxnString get error => _auth.loginError;

  void togglePasswordVisibility() => obscurePassword.toggle();

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required.';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return null;
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await _auth.login(
      username: usernameController.text,
      password: passwordController.text,
    );
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    _auth.clearLoginError();
    super.onClose();
  }
}
