/// API endpoints and request defaults for the DummyJSON backend.
abstract final class ApiConstants {
  static const String baseUrl = 'https://dummyjson.com';

  static const String loginPath = '/auth/login';
  static const String currentUserPath = '/auth/me';
  static const String productsPath = '/products';

  static String productDetailPath(int id) => '$productsPath/$id';

  /// Number of products requested per page.
  static const int productsPageSize = 20;

  static const Duration requestTimeout = Duration(seconds: 20);
}
