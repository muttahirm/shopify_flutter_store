import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class CreateCart {
  final CartRepository _repository;

  const CreateCart(this._repository);

  Future<Cart> call() {
    return _repository.createCart();
  }
}
