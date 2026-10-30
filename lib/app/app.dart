import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/routes/app_pages.dart';
import '../core/theme/app_theme.dart';

class ProductBrowserApp extends StatelessWidget {
  const ProductBrowserApp({super.key, required this.initialRoute});

  /// Decided in `main()` after the persisted session has been restored.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Product Browser',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
    );
  }
}
