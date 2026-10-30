import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/products_repository.dart';

/// State of the first page request. Subsequent pages use [ProductsController.isLoadingMore].
enum ProductsStatus { initial, loading, success, error }

class ProductsController extends GetxController {
  ProductsController(
    this._repository, {
    this.pageSize = ApiConstants.productsPageSize,
    this.loadMoreThreshold = 300,
  });

  final ProductsRepository _repository;
  final int pageSize;

  /// Distance (in pixels) from the bottom at which the next page is requested.
  final double loadMoreThreshold;

  final RxList<Product> products = <Product>[].obs;
  final Rx<ProductsStatus> status = ProductsStatus.initial.obs;

  /// Error for the first page (shown full screen when the list is empty).
  final RxnString errorMessage = RxnString();

  /// Error for a failed refresh while items are already displayed.
  final RxnString refreshError = RxnString();

  final RxBool isLoadingMore = false.obs;
  final RxnString loadMoreError = RxnString();
  final RxBool hasMore = true.obs;

  final ScrollController scrollController = ScrollController();

  int _skip = 0;

  /// Incremented whenever the list is reset so stale in-flight responses
  /// (e.g. a "load more" that was running when the user pulled to refresh)
  /// are discarded instead of being appended to the fresh list.
  int _generation = 0;

  bool get isEmpty =>
      status.value == ProductsStatus.success && products.isEmpty;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadFirstPage();
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.onClose();
  }

  /// Loads page one with a full-screen loader. Used on first open and retry.
  Future<void> loadFirstPage() async {
    if (status.value == ProductsStatus.loading) return;
    status.value = ProductsStatus.loading;
    errorMessage.value = null;
    await _loadFromStart();
  }

  /// Reloads page one in place (pull-to-refresh) and resets pagination.
  /// Returns `false` when the request failed.
  Future<bool> refreshProducts() async {
    refreshError.value = null;
    return _loadFromStart();
  }

  /// Requests the next page. No-op when a page is already loading, when
  /// everything has been loaded, or before the first page succeeded.
  Future<void> loadMore() async {
    if (isLoadingMore.value ||
        !hasMore.value ||
        status.value != ProductsStatus.success) {
      return;
    }

    final generation = _generation;
    isLoadingMore.value = true;
    loadMoreError.value = null;
    try {
      final page = await _repository.getProducts(limit: pageSize, skip: _skip);
      if (generation != _generation) return;

      products.addAll(page.products);
      _skip += page.products.length;
      hasMore.value = page.hasMore && page.products.isNotEmpty;
    } on AppException catch (e) {
      if (generation != _generation) return;
      loadMoreError.value = e.message;
    } finally {
      if (generation == _generation) isLoadingMore.value = false;
    }
  }

  Future<void> retryLoadMore() => loadMore();

  void openProduct(Product product) {
    Get.toNamed(AppRoutes.productDetail(product.id), arguments: product);
  }

  Future<bool> _loadFromStart() async {
    final generation = ++_generation;
    isLoadingMore.value = false;
    loadMoreError.value = null;

    try {
      final page = await _repository.getProducts(limit: pageSize, skip: 0);
      if (generation != _generation) return false;

      products.assignAll(page.products);
      _skip = page.products.length;
      hasMore.value = page.hasMore;
      errorMessage.value = null;
      status.value = ProductsStatus.success;
      return true;
    } on AppException catch (e) {
      if (generation != _generation) return false;

      if (products.isEmpty) {
        errorMessage.value = e.message;
        status.value = ProductsStatus.error;
      } else {
        // Keep showing the existing items; surface the failure transiently.
        refreshError.value = e.message;
        status.value = ProductsStatus.success;
      }
      return false;
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - loadMoreThreshold) {
      loadMore();
    }
  }
}
