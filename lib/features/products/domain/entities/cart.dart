import 'cart_cost.dart';
import 'cart_line.dart';

class Cart {
  final String id;
  final String checkoutUrl;
  final int totalQuantity;
  final List<CartLine> lines;
  final CartCost cost;

  Cart({
    required this.id,
    required this.checkoutUrl,
    required this.totalQuantity,
    required List<CartLine> lines,
    required this.cost,
  }) : lines = List.unmodifiable(lines);
}
