import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/product.dart';
import '../controllers/product_detail_controller.dart';
import '../widgets/product_image.dart';
import '../widgets/status_views.dart';

class ProductDetailPage extends GetView<ProductDetailController> {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.product.value?.title ?? 'Product')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(
            () => controller.isLoading.value && controller.product.value != null
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
      ),
      body: Obx(() {
        final product = controller.product.value;

        if (product == null) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return ErrorView(
            message: controller.errorMessage.value ?? 'Unable to load product.',
            onRetry: controller.load,
          );
        }

        return _ProductDetails(product: product);
      }),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = product.images.isNotEmpty
        ? product.images
        : [product.thumbnail];

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _ImageGallery(images: images),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    label: Text(product.category),
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.sell_outlined, size: 18),
                      label: Text(product.brand!),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(product.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              _PriceRow(product: product),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${product.rating.toStringAsFixed(1)} / 5',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    product.stock > 0
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    color: product.stock > 0
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      product.availabilityStatus ??
                          (product.stock > 0
                              ? '${product.stock} in stock'
                              : 'Out of stock'),
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(product.description, style: theme.textTheme.bodyMedium),
              if (product.warrantyInformation != null ||
                  product.shippingInformation != null ||
                  product.returnPolicy != null) ...[
                const Divider(height: 32),
                Text('Details', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (product.warrantyInformation != null)
                  _InfoRow(
                    icon: Icons.verified_user_outlined,
                    text: product.warrantyInformation!,
                  ),
                if (product.shippingInformation != null)
                  _InfoRow(
                    icon: Icons.local_shipping_outlined,
                    text: product.shippingInformation!,
                  ),
                if (product.returnPolicy != null)
                  _InfoRow(
                    icon: Icons.assignment_return_outlined,
                    text: product.returnPolicy!,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!product.hasDiscount) {
      return Text(
        '\$${product.price.toStringAsFixed(2)}',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${product.discountedPrice.toStringAsFixed(2)}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            '-${product.discountPercentage.toStringAsFixed(0)}%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Swipeable image gallery with a page indicator.
class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.images});

  final List<String> images;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => ProductImage(
              url: widget.images[i],
              fit: BoxFit.contain,
              iconSize: 64,
            ),
          ),
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
