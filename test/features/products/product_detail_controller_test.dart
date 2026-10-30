import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_browser/core/errors/app_exception.dart';
import 'package:product_browser/features/products/presentation/controllers/product_detail_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeProductsRepository repository;

  setUpAll(() => Get.testMode = true);

  setUp(() => repository = FakeProductsRepository());

  test('shows the passed product immediately, then refreshes it', () async {
    final initial = makeProduct(3);
    final controller = ProductDetailController(
      repository,
      productId: 3,
      initialProduct: initial,
    );

    controller.onInit();
    expect(controller.product.value, same(initial));
    expect(controller.isLoading.value, isTrue);

    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading.value, isFalse);
    expect(controller.product.value?.id, 3);
    expect(controller.product.value, isNot(same(initial)));
  });

  test('loads the product by id when none was passed', () async {
    final controller = ProductDetailController(repository, productId: 8);

    await controller.load();

    expect(controller.product.value?.title, 'Product 8');
    expect(controller.errorMessage.value, isNull);
  });

  test('exposes the error only when there is nothing to display', () async {
    final controller = ProductDetailController(repository, productId: 8);
    repository.nextError = const ServerException(404, 'not found');

    await controller.load();

    expect(controller.product.value, isNull);
    expect(controller.errorMessage.value, 'not found');
  });

  test('keeps the initial product when the refresh fails', () async {
    final initial = makeProduct(3);
    final controller = ProductDetailController(
      repository,
      productId: 3,
      initialProduct: initial,
    );
    repository.nextError = const NetworkException();

    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(controller.product.value, same(initial));
    expect(controller.errorMessage.value, isNull);
  });
}
