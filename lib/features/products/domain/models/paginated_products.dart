import '../../../../core/errors/app_exception.dart';
import 'product.dart';

/// One page of `/products` results together with the pagination metadata
/// DummyJSON returns (`total`, `skip`, `limit`).
class PaginatedProducts {
  const PaginatedProducts({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  /// Whether another page exists after this one.
  bool get hasMore => skip + products.length < total;

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    if (rawProducts is! List) {
      throw const ParseException('Products payload is missing the list.');
    }

    return PaginatedProducts(
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? rawProducts.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? rawProducts.length,
    );
  }
}
