import '../entities/product_variant.dart';
import '../repositories/product_repository.dart';

class GetProductVariants {
  final ProductRepository _repository;

  const GetProductVariants(this._repository);

  Future<List<ProductVariant>> call(String productId) {
    if (productId.trim().isEmpty) {
      throw ArgumentError.value(
        productId,
        'productId',
        'Product ID must not be empty.',
      );
    }

    return _repository.getProductVariants(productId);
  }
}
