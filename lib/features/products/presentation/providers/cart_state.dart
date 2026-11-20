import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_warning.dart';

class CartState {
  final Cart? cart;
  final String? noticeMessage;
  final bool isLoading;
  final String? errorMessage;
  final bool requiresRefresh;
  final List<CartWarning> warnings;

  const CartState({
    this.cart,
    this.noticeMessage,
    this.isLoading = false,
    this.errorMessage,
    this.requiresRefresh = false,
    this.warnings = const [],
  });
}
