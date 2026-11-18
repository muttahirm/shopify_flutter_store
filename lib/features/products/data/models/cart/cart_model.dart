import '../../../domain/entities/cart.dart';
import 'cart_cost_model.dart';
import 'cart_line_model.dart';

class CartModel {
  final String id;
  final String checkoutUrl;
  final int totalQuantity;
  final List<CartLineModel> lines;
  final CartCostModel cost;

  CartModel({
    required this.id,
    required this.checkoutUrl,
    required this.totalQuantity,
    required List<CartLineModel> lines,
    required this.cost,
  }) : lines = List.unmodifiable(lines);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final connection = json['lines'] as Map<String, dynamic>;
    final nodes = connection['nodes'] as List<dynamic>;

    return CartModel(
      id: json['id'] as String,
      checkoutUrl: json['checkoutUrl'] as String,
      totalQuantity: json['totalQuantity'] as int,
      lines: nodes
          .map((node) => CartLineModel.fromJson(node as Map<String, dynamic>))
          .toList(growable: false),
      cost: CartCostModel.fromJson(json['cost'] as Map<String, dynamic>),
    );
  }

  Cart toEntity() {
    return Cart(
      id: id,
      checkoutUrl: checkoutUrl,
      totalQuantity: totalQuantity,
      lines: lines.map((line) => line.toEntity()).toList(growable: false),
      cost: cost.toEntity(),
    );
  }
}
