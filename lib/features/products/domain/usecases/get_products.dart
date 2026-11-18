import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts {
  final ProductRepository _repository;

  const GetProducts(this._repository);

  Future<List<Product>> call({int limit = 20}) {
    if (limit < 1 || limit > 250) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 250.');
    }

    return _repository.getProducts(limit: limit);
  }
}
