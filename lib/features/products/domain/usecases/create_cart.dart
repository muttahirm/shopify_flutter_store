import '../entities/cart_mutation_result.dart';
import '../repositories/cart_repository.dart';

class CreateCart {
  final CartRepository _repository;

  const CreateCart(this._repository);

  Future<CartMutationResult> call() {
    return _repository.createCart();
  }
}
