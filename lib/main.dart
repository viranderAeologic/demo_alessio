import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/bindings/initial_binding.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register app-wide dependencies before any route is built.
  InitialBinding().dependencies();

  // Restore the persisted session (if any) so the first route and the auth
  // middleware can rely on a known authentication state.
  final auth = Get.find<AuthController>();
  await auth.restoreSession();

  runApp(
    ProductBrowserApp(
      initialRoute: auth.isAuthenticated.value
          ? AppRoutes.products
          : AppRoutes.login,
    ),
  );
}
