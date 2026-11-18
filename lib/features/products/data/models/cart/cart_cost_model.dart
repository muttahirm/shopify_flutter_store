import '../../../domain/entities/cart_cost.dart';

class CartCostModel {
  final String subtotalAmount;
  final String totalAmount;
  final String currencyCode;

  const CartCostModel({
    required this.subtotalAmount,
    required this.totalAmount,
    required this.currencyCode,
  });

  factory CartCostModel.fromJson(Map<String, dynamic> json) {
    final subtotal = json['subtotalAmount'] as Map<String, dynamic>;
    final total = json['totalAmount'] as Map<String, dynamic>;

    final subtotalCurrency = subtotal['currencyCode'] as String;
    final totalCurrency = total['currencyCode'] as String;

    if (subtotalCurrency != totalCurrency) {
      throw const FormatException(
        'Cart subtotal and total currencies do not match.',
      );
    }

    return CartCostModel(
      subtotalAmount: subtotal['amount'] as String,
      totalAmount: total['amount'] as String,
      currencyCode: totalCurrency,
    );
  }

  CartCost toEntity() {
    return CartCost(
      subtotalAmount: subtotalAmount,
      totalAmount: totalAmount,
      currencyCode: currencyCode,
    );
  }
}
