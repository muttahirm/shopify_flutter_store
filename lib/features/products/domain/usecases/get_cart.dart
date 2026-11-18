import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class GetCart {
  final CartRepository _repository;

  const GetCart(this._repository);

  Future<Cart?> call(String cartId) {
    if (cartId.trim().isEmpty) {
      throw ArgumentError.value(cartId, 'cartId', 'Cart ID must not be empty.');
    }

    return _repository.getCart(cartId);
  }
}
