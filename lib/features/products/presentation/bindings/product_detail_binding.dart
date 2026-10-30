import 'package:get/get.dart';

import '../../domain/models/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../controllers/product_detail_controller.dart';

class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    final id = int.tryParse(Get.parameters['id'] ?? '') ?? -1;
    final arguments = Get.arguments;

    Get.lazyPut<ProductDetailController>(
      () => ProductDetailController(
        Get.find<ProductsRepository>(),
        productId: id,
        initialProduct: arguments is Product ? arguments : null,
      ),
    );
  }
}
