import '../entities/cart.dart';
import '../entities/cart_mutation_result.dart';

abstract interface class CartRepository {
  Future<CartMutationResult> createCart();

  Future<Cart?> getCart(String cartId);

  Future<CartMutationResult> addItem({
    required String cartId,
    required String variantId,
    required int quantity,
  });

  Future<CartMutationResult> updateItemQuantity({
    required String cartId,
    required String lineId,
    required int quantity,
  });

  Future<CartMutationResult> removeItem({
    required String cartId,
    required String lineId,
  });
}
