import '../entities/cart_mutation_result.dart';
import '../repositories/cart_repository.dart';

class AddCartItem {
  final CartRepository _repository;

  const AddCartItem(this._repository);

  Future<CartMutationResult> call({
    required String cartId,
    required String variantId,
    int quantity = 1,
  }) {
    if (cartId.trim().isEmpty) {
      throw ArgumentError.value(cartId, 'cartId', 'Cart ID must not be empty.');
    }

    if (variantId.trim().isEmpty) {
      throw ArgumentError.value(
        variantId,
        'variantId',
        'Variant ID must not be empty.',
      );
    }

    if (quantity < 1) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Quantity must be at least 1.',
      );
    }

    return _repository.addItem(
      cartId: cartId,
      variantId: variantId,
      quantity: quantity,
    );
  }
}
