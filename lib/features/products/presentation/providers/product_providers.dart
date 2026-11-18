import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/shopify_client.dart';
import '../../data/datasources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products.dart';

// 1. Data source receives the configured Dio client.
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(shopifyClientProvider);

  return ProductRemoteDataSource(dio);
});

// 2. Expose the implementation through the domain contract.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dataSource = ref.watch(productRemoteDataSourceProvider);

  return ProductRepositoryImpl(dataSource);
});

// 3. Use case receives the repository.
final getProductsProvider = Provider<GetProducts>((ref) {
  final repository = ref.watch(productRepositoryProvider);

  return GetProducts(repository);
});

// 4. Fetch products and expose loading, data, and error states.
final productsProvider = FutureProvider<List<Product>>((ref) {
  final getProducts = ref.watch(getProductsProvider);

  return getProducts(limit: 20);
});
