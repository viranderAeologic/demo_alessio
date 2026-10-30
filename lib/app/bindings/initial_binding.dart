import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/products/data/datasources/products_remote_data_source.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';

/// Registers app-wide singletons: infrastructure, repositories and the
/// session controller. Route bindings only add route-scoped controllers.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core
    Get.put<TokenStorage>(SecureTokenStorage(), permanent: true);
    Get.put<ApiClient>(
      ApiClient(tokenStorage: Get.find<TokenStorage>()),
      permanent: true,
    );

    // Auth
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDataSource>(),
        tokenStorage: Get.find<TokenStorage>(),
      ),
      fenix: true,
    );
    Get.put<AuthController>(
      AuthController(Get.find<AuthRepository>()),
      permanent: true,
    );

    // Products
    Get.lazyPut<ProductsRemoteDataSource>(
      () => ProductsRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<ProductsRepository>(
      () => ProductsRepositoryImpl(Get.find<ProductsRemoteDataSource>()),
      fenix: true,
    );
  }
}
