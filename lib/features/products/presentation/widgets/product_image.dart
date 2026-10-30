import 'package:flutter/material.dart';

/// Network image with a loading placeholder and a graceful fallback.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 32,
  });

  final String url;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholderColor = scheme.surfaceContainerHighest;

    if (url.isEmpty) {
      return ColoredBox(
        color: placeholderColor,
        child: Icon(Icons.image_not_supported_outlined, size: iconSize),
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: placeholderColor,
          child: const Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: placeholderColor,
        child: Icon(Icons.broken_image_outlined, size: iconSize),
      ),
    );
  }
}
