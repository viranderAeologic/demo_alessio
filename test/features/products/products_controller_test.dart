import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_browser/core/errors/app_exception.dart';
import 'package:product_browser/features/products/presentation/controllers/products_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeProductsRepository repository;
  late ProductsController controller;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
  });

  setUp(() {
    repository = FakeProductsRepository(total: 45);
    controller = ProductsController(repository, pageSize: 20);
  });

  tearDown(() => controller.onClose());

  /// Lets the queued futures from `onInit` finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('loads the first page on init', () async {
    controller.onInit();
    expect(controller.status.value, ProductsStatus.loading);

    await settle();

    expect(controller.status.value, ProductsStatus.success);
    expect(controller.products, hasLength(20));
    expect(controller.hasMore.value, isTrue);
    expect(repository.calls.single, (limit: 20, skip: 0));
  });

  test('shows the error state when the first page fails', () async {
    repository.nextError = const NetworkException('offline');

    await controller.loadFirstPage();

    expect(controller.status.value, ProductsStatus.error);
    expect(controller.errorMessage.value, 'offline');
    expect(controller.products, isEmpty);
  });

  test('retry after an error loads the list', () async {
    repository.nextError = const NetworkException();
    await controller.loadFirstPage();
    expect(controller.status.value, ProductsStatus.error);

    await controller.loadFirstPage();

    expect(controller.status.value, ProductsStatus.success);
    expect(controller.errorMessage.value, isNull);
    expect(controller.products, hasLength(20));
  });

  test('reports an empty list when the API returns no products', () async {
    repository.total = 0;

    await controller.loadFirstPage();

    expect(controller.status.value, ProductsStatus.success);
    expect(controller.isEmpty, isTrue);
    expect(controller.hasMore.value, isFalse);
  });

  group('loadMore', () {
    test('appends pages using skip and stops at the end', () async {
      await controller.loadFirstPage();

      await controller.loadMore();
      expect(controller.products, hasLength(40));
      expect(controller.hasMore.value, isTrue);

      await controller.loadMore();
      expect(controller.products, hasLength(45));
      expect(controller.hasMore.value, isFalse);

      await controller.loadMore();
      expect(repository.calls.map((c) => c.skip), [0, 20, 40]);
    });

    test('does not fire while another page is loading', () async {
      await controller.loadFirstPage();
      repository.gate = Completer<void>();

      final first = controller.loadMore();
      final second = controller.loadMore();
      expect(controller.isLoadingMore.value, isTrue);

      repository.gate!.complete();
      await Future.wait([first, second]);

      expect(repository.calls, hasLength(2)); // first page + one load more
      expect(controller.products, hasLength(40));
    });

    test('does nothing before the first page succeeded', () async {
      await controller.loadMore();

      expect(repository.calls, isEmpty);
    });

    test('exposes an inline error and keeps existing items', () async {
      await controller.loadFirstPage();
      repository.nextError = const ServerException(500, 'server down');

      await controller.loadMore();

      expect(controller.products, hasLength(20));
      expect(controller.loadMoreError.value, 'server down');
      expect(controller.isLoadingMore.value, isFalse);
      expect(controller.hasMore.value, isTrue);

      await controller.retryLoadMore();
      expect(controller.loadMoreError.value, isNull);
      expect(controller.products, hasLength(40));
    });
  });

  group('refreshProducts', () {
    test('reloads from the start and resets pagination', () async {
      await controller.loadFirstPage();
      await controller.loadMore();
      expect(controller.products, hasLength(40));

      final ok = await controller.refreshProducts();

      expect(ok, isTrue);
      expect(controller.products, hasLength(20));
      expect(controller.hasMore.value, isTrue);
      expect(repository.calls.last, (limit: 20, skip: 0));

      await controller.loadMore();
      expect(repository.calls.last.skip, 20);
    });

    test('keeps the current items and reports a transient error', () async {
      await controller.loadFirstPage();
      repository.nextError = const NetworkException('offline');

      final ok = await controller.refreshProducts();

      expect(ok, isFalse);
      expect(controller.status.value, ProductsStatus.success);
      expect(controller.products, hasLength(20));
      expect(controller.refreshError.value, 'offline');
    });

    test(
      'discards a stale load-more response that completes afterwards',
      () async {
        await controller.loadFirstPage();

        final gate = Completer<void>();
        repository.gate = gate;
        final staleLoadMore = controller.loadMore();

        repository.gate = null;
        await controller.refreshProducts();
        expect(controller.products, hasLength(20));

        // Now let the old "load more" finish; it must not be appended.
        gate.complete();
        await staleLoadMore;

        expect(controller.products, hasLength(20));
        expect(controller.isLoadingMore.value, isFalse);
      },
    );
  });
}
