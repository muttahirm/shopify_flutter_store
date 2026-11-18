import '../../../domain/entities/cart_line.dart';

class CartLineModel {
  final String id;
  final String variantId;
  final String productTitle;
  final String variantTitle;
  final String? imageUrl;
  final int quantity;
  final String totalAmount;
  final String currencyCode;

  const CartLineModel({
    required this.id,
    required this.variantId,
    required this.productTitle,
    required this.variantTitle,
    required this.imageUrl,
    required this.quantity,
    required this.totalAmount,
    required this.currencyCode,
  });

  factory CartLineModel.fromJson(Map<String, dynamic> json) {
    final merchandise = json['merchandise'] as Map<String, dynamic>;

    if (merchandise['__typename'] != 'ProductVariant') {
      throw const FormatException('Unsupported cart merchandise type.');
    }

    final product = merchandise['product'] as Map<String, dynamic>;
    final image = merchandise['image'] as Map<String, dynamic>?;
    final cost = json['cost'] as Map<String, dynamic>;
    final total = cost['totalAmount'] as Map<String, dynamic>;

    return CartLineModel(
      id: json['id'] as String,
      variantId: merchandise['id'] as String,
      productTitle: product['title'] as String,
      variantTitle: merchandise['title'] as String,
      imageUrl: image?['url'] as String?,
      quantity: json['quantity'] as int,
      totalAmount: total['amount'] as String,
      currencyCode: total['currencyCode'] as String,
    );
  }

  CartLine toEntity() {
    return CartLine(
      id: id,
      variantId: variantId,
      productTitle: productTitle,
      variantTitle: variantTitle,
      imageUrl: imageUrl,
      quantity: quantity,
      totalAmount: totalAmount,
      currencyCode: currencyCode,
    );
  }
}
