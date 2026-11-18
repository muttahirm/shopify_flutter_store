import '../entities/cart.dart';

abstract interface class CartRepository {
  Future<Cart> createCart();

  Future<Cart?> getCart(String cartId);

  Future<Cart> addItem({
    required String cartId,
    required String variantId,
    required int quantity,
  });

  Future<Cart> updateItemQuantity({
    required String cartId,
    required String lineId,
    required int quantity,
  });

  Future<Cart> removeItem({required String cartId, required String lineId});
}
