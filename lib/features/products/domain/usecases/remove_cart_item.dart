import '../entities/cart_mutation_result.dart';
import '../repositories/cart_repository.dart';

class RemoveCartItem {
  final CartRepository _repository;

  const RemoveCartItem(this._repository);

  Future<CartMutationResult> call({
    required String cartId,
    required String lineId,
  }) {
    if (cartId.trim().isEmpty) {
      throw ArgumentError.value(cartId, 'cartId', 'Cart ID must not be empty.');
    }

    if (lineId.trim().isEmpty) {
      throw ArgumentError.value(lineId, 'lineId', 'Line ID must not be empty.');
    }

    return _repository.removeItem(cartId: cartId, lineId: lineId);
  }
}
