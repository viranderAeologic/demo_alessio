import 'package:flutter_test/flutter_test.dart';
import 'package:product_browser/core/errors/app_exception.dart';
import 'package:product_browser/features/products/domain/models/paginated_products.dart';
import 'package:product_browser/features/products/domain/models/product.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a full DummyJSON payload', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Essence Mascara',
        'description': 'Lash princess',
        'category': 'beauty',
        'price': 9.99,
        'discountPercentage': 10.48,
        'rating': 2.56,
        'stock': 99,
        'brand': 'Essence',
        'thumbnail': 'https://x/thumb.png',
        'images': ['https://x/1.png', 'https://x/2.png'],
        'availabilityStatus': 'In Stock',
      });

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara');
      expect(product.price, 9.99);
      expect(product.brand, 'Essence');
      expect(product.images, hasLength(2));
      expect(product.hasDiscount, isTrue);
      expect(product.discountedPrice, closeTo(8.94, 0.01));
    });

    test('tolerates missing optional fields and integer prices', () {
      final product = Product.fromJson({'id': 7, 'title': 'Bare', 'price': 20});

      expect(product.price, 20.0);
      expect(product.brand, isNull);
      expect(product.images, isEmpty);
      expect(product.hasDiscount, isFalse);
    });

    test('throws ParseException when required fields are missing', () {
      expect(
        () => Product.fromJson({'title': 'no id'}),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('PaginatedProducts.fromJson', () {
    test('parses products and pagination metadata', () {
      final page = PaginatedProducts.fromJson({
        'products': [
          {'id': 1, 'title': 'A'},
          {'id': 2, 'title': 'B'},
        ],
        'total': 10,
        'skip': 0,
        'limit': 2,
      });

      expect(page.products.map((p) => p.id), [1, 2]);
      expect(page.total, 10);
      expect(page.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      final page = PaginatedProducts.fromJson({
        'products': [
          {'id': 9, 'title': 'I'},
          {'id': 10, 'title': 'J'},
        ],
        'total': 10,
        'skip': 8,
        'limit': 2,
      });

      expect(page.hasMore, isFalse);
    });

    test('throws ParseException when the list is missing', () {
      expect(
        () => PaginatedProducts.fromJson({'total': 0}),
        throwsA(isA<ParseException>()),
      );
    });
  });
}
