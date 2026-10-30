import '../../domain/models/paginated_products.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_data_source.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<PaginatedProducts> getProducts({
    required int limit,
    required int skip,
  }) => _remote.fetchProducts(limit: limit, skip: skip);

  @override
  Future<Product> getProduct(int id) => _remote.fetchProduct(id);
}
