import 'package:get/get.dart';

import '../../domain/repositories/products_repository.dart';
import '../controllers/products_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductsController>(
      () => ProductsController(Get.find<ProductsRepository>()),
    );
  }
}
