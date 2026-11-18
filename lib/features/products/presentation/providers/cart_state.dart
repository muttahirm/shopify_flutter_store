import '../../domain/entities/cart.dart';

class CartState {
  final Cart? cart;
  final bool isLoading;
  final String? errorMessage;
  final bool requiresRefresh;

  const CartState({
    this.cart,
    this.isLoading = false,
    this.errorMessage,
    this.requiresRefresh = false,
  });
}
