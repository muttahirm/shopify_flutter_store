import '../entities/product.dart';
import '../entities/product_variant.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts({int limit = 20});
  Future<List<ProductVariant>> getProductVariants(String productId);
}
