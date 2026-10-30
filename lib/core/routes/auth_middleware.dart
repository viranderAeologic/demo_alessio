import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'app_routes.dart';

/// Redirects unauthenticated users to the login screen.
///
/// Relies on [AuthController] being registered permanently by the initial
/// binding and having restored the session before the first route is built.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (auth.isAuthenticated.value) return null;
    return const RouteSettings(name: AppRoutes.login);
  }
}

/// Keeps already-authenticated users away from the login screen.
class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated.value) return null;
    return const RouteSettings(name: AppRoutes.products);
  }
}
