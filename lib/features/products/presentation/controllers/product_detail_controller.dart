import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/products_repository.dart';

class ProductDetailController extends GetxController {
  ProductDetailController(
    this._repository, {
    required this.productId,
    this._initialProduct,
  });

  final ProductsRepository _repository;
  final int productId;
  final Product? _initialProduct;

  final Rxn<Product> product = Rxn<Product>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    // Show the product passed from the list immediately, then refresh it
    // from `/products/{id}` so the detail page always has the full payload.
    product.value = _initialProduct;
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = null;
    try {
      product.value = await _repository.getProduct(productId);
    } on AppException catch (e) {
      // Only block the screen with an error when there is nothing to show.
      if (product.value == null) errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
