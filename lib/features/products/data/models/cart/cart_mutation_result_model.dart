import '../../../domain/entities/cart_mutation_result.dart';
import 'cart_model.dart';
import 'cart_warning_model.dart';

class CartMutationResultModel {
  final CartModel cart;
  final List<CartWarningModel> warnings;

  CartMutationResultModel({
    required this.cart,
    required List<CartWarningModel> warnings,
  }) : warnings = List.unmodifiable(warnings);

  CartMutationResult toEntity() {
    return CartMutationResult(
      cart: cart.toEntity(),
      warnings: warnings.map((warning) => warning.toEntity()).toList(),
    );
  }
}
