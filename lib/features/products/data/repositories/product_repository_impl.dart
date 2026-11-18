import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  const ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Product>> getProducts({int limit = 20}) async {
    final models = await _remoteDataSource.getProducts(limit: limit);

    return models.map((model) => model.toEntity()).toList(growable: false);
  }
}
