import 'dart:async';

import 'package:product_browser/core/storage/token_storage.dart';
import 'package:product_browser/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:product_browser/features/auth/domain/models/auth_session.dart';
import 'package:product_browser/features/auth/domain/models/auth_user.dart';
import 'package:product_browser/features/auth/domain/repositories/auth_repository.dart';
import 'package:product_browser/features/products/domain/models/paginated_products.dart';
import 'package:product_browser/features/products/domain/models/product.dart';
import 'package:product_browser/features/products/domain/repositories/products_repository.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;
}

const testUser = AuthUser(
  id: 1,
  username: 'emilys',
  email: 'emily@x.com',
  firstName: 'Emily',
  lastName: 'Johnson',
);

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Future<AuthSession> Function(String username, String password)? onLogin;
  Future<AuthUser> Function()? onCurrentUser;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) => onLogin!(username, password);

  @override
  Future<AuthUser> currentUser() => onCurrentUser!();
}

class FakeAuthRepository implements AuthRepository {
  Future<AuthSession> Function(String username, String password)? onLogin;
  Future<AuthSession?> Function()? onRestore;
  int logoutCalls = 0;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) => onLogin!(username, password);

  @override
  Future<AuthSession?> restoreSession() =>
      onRestore?.call() ?? Future.value(null);

  @override
  Future<void> logout() async => logoutCalls++;
}

Product makeProduct(int id) => Product(
  id: id,
  title: 'Product $id',
  description: 'Description $id',
  category: 'category',
  price: 10.0 + id,
  discountPercentage: 0,
  rating: 4.5,
  stock: 5,
  thumbnail: '',
  images: const [],
);

PaginatedProducts makePage({
  required int skip,
  required int limit,
  required int total,
}) {
  final count = (total - skip).clamp(0, limit);
  return PaginatedProducts(
    products: List.generate(count, (i) => makeProduct(skip + i + 1)),
    total: total,
    skip: skip,
    limit: limit,
  );
}

class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({this.total = 45});

  int total;
  final List<({int limit, int skip})> calls = [];

  /// When set, the next [getProducts] call throws this error.
  Object? nextError;

  /// When set, [getProducts] waits on this completer before returning so
  /// tests can control ordering of concurrent requests.
  Completer<void>? gate;

  @override
  Future<PaginatedProducts> getProducts({
    required int limit,
    required int skip,
  }) async {
    calls.add((limit: limit, skip: skip));
    final pendingGate = gate;
    if (pendingGate != null) await pendingGate.future;

    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return makePage(skip: skip, limit: limit, total: total);
  }

  @override
  Future<Product> getProduct(int id) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return makeProduct(id);
  }
}
