import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class UpdateCartItemQuantity {
  final CartRepository _repository;

  const UpdateCartItemQuantity(this._repository);

  Future<Cart> call({
    required String cartId,
    required String lineId,
    required int quantity,
  }) {
    if (cartId.trim().isEmpty) {
      throw ArgumentError.value(cartId, 'cartId', 'Cart ID must not be empty.');
    }

    if (lineId.trim().isEmpty) {
      throw ArgumentError.value(lineId, 'lineId', 'Line ID must not be empty.');
    }

    if (quantity < 1) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Quantity must be at least 1. Use RemoveCartItem for removal.',
      );
    }

    return _repository.updateItemQuantity(
      cartId: cartId,
      lineId: lineId,
      quantity: quantity,
    );
  }
}
