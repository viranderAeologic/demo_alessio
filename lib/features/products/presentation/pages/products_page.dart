import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/products_controller.dart';
import '../widgets/pagination_footer.dart';
import '../widgets/product_card.dart';
import '../widgets/status_views.dart';

class ProductsPage extends GetView<ProductsController> {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final user = auth.user.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Products'),
              if (user != null)
                Text(
                  'Hi, ${user.firstName.isNotEmpty ? user.firstName : user.username}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, auth),
          ),
        ],
      ),
      body: Obx(() {
        final status = controller.status.value;
        final products = controller.products;

        if (status == ProductsStatus.initial ||
            (status == ProductsStatus.loading && products.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (status == ProductsStatus.error && products.isEmpty) {
          return ErrorView(
            message:
                controller.errorMessage.value ?? 'Unable to load products.',
            onRetry: controller.loadFirstPage,
          );
        }

        if (products.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: EmptyView(onRefresh: () => _refresh(context)),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView.builder(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length + 1,
            itemBuilder: (context, index) {
              if (index == products.length) {
                return Obx(
                  () => PaginationFooter(
                    isLoading: controller.isLoadingMore.value,
                    hasMore: controller.hasMore.value,
                    error: controller.loadMoreError.value,
                    onRetry: controller.retryLoadMore,
                  ),
                );
              }
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => controller.openProduct(product),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final ok = await controller.refreshProducts();
    if (ok || !context.mounted) return;

    final message = controller.refreshError.value;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Refresh failed: $message'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _refresh(context),
          ),
        ),
      );
  }

  Future<void> _confirmLogout(BuildContext context, AuthController auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to browse products.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.logout();
  }
}
