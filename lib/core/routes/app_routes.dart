/// Named routes used with GetX navigation.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String products = '/products';

  /// Route pattern; use [productDetail] to build a concrete path.
  static const String productDetailPattern = '/products/:id';

  static String productDetail(int id) => '/products/$id';
}
