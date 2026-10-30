import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/login_controller.dart';

/// Route-level binding for the login screen.
///
/// [AuthController] itself is provided by the initial binding; this only adds
/// the form controller for the lifetime of the login route.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<AuthController>()),
    );
  }
}
