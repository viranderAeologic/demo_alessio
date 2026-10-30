import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/paginated_products.dart';
import '../../domain/models/product.dart';

abstract class ProductsRemoteDataSource {
  Future<PaginatedProducts> fetchProducts({
    required int limit,
    required int skip,
  });

  Future<Product> fetchProduct(int id);
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  ProductsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<PaginatedProducts> fetchProducts({
    required int limit,
    required int skip,
  }) async {
    final json = await _client.get(
      ApiConstants.productsPath,
      query: {'limit': '$limit', 'skip': '$skip'},
    );
    return PaginatedProducts.fromJson(json);
  }

  @override
  Future<Product> fetchProduct(int id) async {
    final json = await _client.get(ApiConstants.productDetailPath(id));
    return Product.fromJson(json);
  }
}
