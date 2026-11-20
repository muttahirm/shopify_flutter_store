import 'cart.dart';
import 'cart_warning.dart';

class CartMutationResult {
  final Cart cart;
  final List<CartWarning> warnings;

  CartMutationResult({
    required this.cart,
    List<CartWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);
}
