import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_mutation_result.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;

  const CartRepositoryImpl(this._remoteDataSource);

  @override
  Future<CartMutationResult> createCart() async {
    final model = await _remoteDataSource.createCart();

    return model.toEntity();
  }

  @override
  Future<Cart?> getCart(String cartId) async {
    final model = await _remoteDataSource.getCart(cartId);

    return model?.toEntity();
  }

  @override
  Future<CartMutationResult> addItem({
    required String cartId,
    required String variantId,
    required int quantity,
  }) async {
    final model = await _remoteDataSource.addItem(
      cartId: cartId,
      variantId: variantId,
      quantity: quantity,
    );

    return model.toEntity();
  }

  @override
  Future<CartMutationResult> updateItemQuantity({
    required String cartId,
    required String lineId,
    required int quantity,
  }) async {
    final model = await _remoteDataSource.updateItemQuantity(
      cartId: cartId,
      lineId: lineId,
      quantity: quantity,
    );

    return model.toEntity();
  }

  @override
  Future<CartMutationResult> removeItem({
    required String cartId,
    required String lineId,
  }) async {
    final model = await _remoteDataSource.removeItem(
      cartId: cartId,
      lineId: lineId,
    );

    return model.toEntity();
  }
}
