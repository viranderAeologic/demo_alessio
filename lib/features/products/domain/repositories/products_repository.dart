import '../models/paginated_products.dart';
import '../models/product.dart';

abstract class ProductsRepository {
  /// Fetches a page of products using `limit`/`skip` pagination.
  Future<PaginatedProducts> getProducts({
    required int limit,
    required int skip,
  });

  /// Fetches a single product by id.
  Future<Product> getProduct(int id);
}
